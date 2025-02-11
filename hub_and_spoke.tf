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

