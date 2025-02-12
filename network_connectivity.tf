##############################
# VPN & VPN CONNECTIVITY
##############################

# Creates a Virtual Network Gateway for VPN connectivity
# This resource enables secure site-to-site VPN connections to Azure
resource "azurerm_virtual_network_gateway" "vpn_gw" {
  name                = "vpn-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"  # Uses dynamic routing for VPN connections
  active_active       = false         # Single active VPN gateway instance
  enable_bgp          = true          # Enables Border Gateway Protocol (BGP) for dynamic routing

  sku = "VpnGw1"  # VPN Gateway SKU selection

  ip_configuration {
    name                          = "vpn-gw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gw_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }
}

# Creates an ExpressRoute Circuit for dedicated private connectivity
# This resource establishes a high-speed private connection to on-premises data centers
resource "azurerm_express_route_circuit" "expressroute" {
  name                  = "expressroute-circuit"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_provider_name = "Equinix"    # ExpressRoute provider
  peering_location      = "Amsterdam"  # Location where peering is established
  bandwidth_in_mbps     = 1000         # 1 Gbps bandwidth capacity

  sku {
    tier   = "Standard"       # Standard ExpressRoute tier
    family = "MeteredData"    # Billing model: metered data transfer
  }
}

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

# Internal Load Balancer (Now it is protected by Firewall)
resource "azurerm_lb" "internal_lb" {
  name                = "internal-load-balancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "internal-lb-ip"
    subnet_id            = azurerm_subnet.hub_subnet.id  # Привязан к внутренней сети
    private_ip_address_allocation = "Dynamic"
  }
}

# Backend pool для Load Balancer
resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "backend-pool"
}

# HTTP правило для Internal Load Balancer
resource "azurerm_lb_rule" "http_lb_rule" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "internal-lb-ip"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
}

