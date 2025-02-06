##############################
# VPN & EXPRESSROUTE GATEWAYS
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