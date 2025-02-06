##############################
# PROVIDER CONFIGURATION
##############################

# Configures the Azure provider with necessary credentials
provider "azurerm" {
  features {}

  client_id       = var.service_principal_id
  client_secret   = var.service_principal_key
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Specifies required provider version for compatibility
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.90.0"  # Latest version
    }
  }
}

/*terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "tfstatebackend"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}*/

##############################
# RESOURCE GROUP
##############################

# Creates a resource group to manage all infrastructure resources
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  lifecycle {
    prevent_destroy = false
  }
}

##############################
# VIRTUAL NETWORKS (HUB-AND-SPOKE)
##############################

# Creates the Hub virtual network
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Creates Spoke1 virtual network
resource "azurerm_virtual_network" "spoke1_vnet" {
  name                = "spoke1-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

# Creates Spoke2 virtual network
resource "azurerm_virtual_network" "spoke2_vnet" {
  name                = "spoke2-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.2.0.0/16"]
}

##############################
# VIRTUAL NETWORK PEERING
##############################

# Establishes peering between Hub and Spoke1
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke1_vnet.id
}

# Establishes peering between Hub and Spoke2
resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                      = "hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke2_vnet.id
}

##############################
# SUBNETS
##############################

# Defines GatewaySubnet for VPN and ExpressRoute connectivity
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Defines Private Link Subnet for secure private endpoints
resource "azurerm_subnet" "private_link_subnet" {
  name                 = "PrivateLinkSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Defines Firewall Subnet required for Azure Firewall deployment
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Subnet for general workloads within the Hub network
resource "azurerm_subnet" "hub_subnet" {
  name                 = "hub-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.4.0/24"] 
}

##############################
# PUBLIC IPS
##############################

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall_pip" {
  name                = "firewall-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gw_pip" {
  name                = "vpn-gw-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

##############################
# SECURITY - FIREWALL & ROUTING
##############################

# Creates an Azure Firewall Policy
resource "azurerm_firewall_policy" "hub_firewall_policy" {
  name                = "hub-firewall-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Deploys Azure Firewall in the Hub network
resource "azurerm_firewall" "hub_firewall" {
  name                = "hub-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "firewall-ipconfig"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

# Creates a route table for controlling traffic flow
resource "azurerm_route_table" "hub_route_table" {
  name                = "hub-udr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

##############################
# PRIVATE ENDPOINTS
##############################

# Configures a private endpoint for SQL Server
resource "azurerm_private_endpoint" "private_sql" {
  name                = "private-sql-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_link_subnet.id

  private_service_connection {
    name                           = "private-sql-connection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}

##############################
# EXPRESSROUTE & VPN CONNECTIVITY
##############################

# Configures Local Network Gateway for on-premises VPN connectivity
resource "azurerm_local_network_gateway" "onprem_gw" {
  name                = "onprem-gw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  gateway_address = "203.0.113.1"
  address_space   = ["192.168.1.0/24"]

  bgp_settings {
    asn                 = 65001
    bgp_peering_address = "203.0.113.2"
  }
}

# Establishes a VPN connection to on-premises network
resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  name                       = "vpn-connection"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem_gw.id
  shared_key                 = "YOUR_SECRET_KEY"
}

##############################
# VIRTUAL HUB & ROUTING
##############################

# Creates a Virtual Hub for centralizing connectivity
resource "azurerm_virtual_hub" "hub" {
  name                = "virtual-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  virtual_wan_id      = azurerm_virtual_wan.main_vwan.id
  address_prefix      = "10.5.0.0/24"
}

# Creates the default route table for Virtual Hub
resource "azurerm_virtual_hub_route_table" "default_route_table" {
  name           = "defaultRouteTable"
  virtual_hub_id = azurerm_virtual_hub.hub.id

  route {
    name             = "default-route"
    destinations_type = "CIDR"
    destinations     = ["0.0.0.0/0"]
    next_hop_type    = "ResourceId"  
    next_hop         = azurerm_firewall.hub_firewall.id  # Route all traffic through Firewall
  }
}

# Virtual Hub connection to Spoke1
resource "azurerm_virtual_hub_connection" "spoke1_connection" {
  name                      = "spoke1-connection"
  virtual_hub_id            = azurerm_virtual_hub.hub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke1_vnet.id
  internet_security_enabled = true
}

# Virtual Hub connection to Spoke2
resource "azurerm_virtual_hub_connection" "spoke2_connection" {
  name                      = "spoke2-connection"
  virtual_hub_id            = azurerm_virtual_hub.hub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke2_vnet.id
  internet_security_enabled = true
}

##############################
# EXPRESSROUTE GATEWAY
##############################

# Creates an ExpressRoute Gateway for hybrid connectivity
resource "azurerm_express_route_gateway" "er_gateway" {
  name                = "express-route-gw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_hub_id      = azurerm_virtual_hub.hub.id
  scale_units         = 2

  depends_on = [
    azurerm_virtual_hub.hub,
    azurerm_virtual_hub_connection.spoke1_connection,
    azurerm_virtual_hub_connection.spoke2_connection
  ]
}

##############################
# PUBLIC LOAD BALANCER
##############################

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb_ip" {
  name                = "lb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Deploys a public Load Balancer
resource "azurerm_lb" "public_lb" {
  name                = "public-load-balancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public-lb-ip"
    public_ip_address_id = azurerm_public_ip.lb_ip.id
  }
}

# Backend pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  loadbalancer_id = azurerm_lb.public_lb.id
  name            = "backend-pool"
}

# HTTP Load Balancer rule
resource "azurerm_lb_rule" "http_lb_rule" {
  loadbalancer_id                = azurerm_lb.public_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-lb-ip"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
}

##############################
# ROUTING CONFIGURATION
##############################

# Default route: Forward all traffic to Firewall
resource "azurerm_route" "default_route" {
  name                   = "all-traffic-to-firewall"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub_route_table.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.3.4" # Replace with actual Private IP of Firewall
}

##############################
# OUTPUT VALUES
##############################

# Outputs Route Table ID
output "route_table_id" {
  value = azurerm_virtual_hub_route_table.default_route_table.id
}