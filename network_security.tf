##############################
# NETWORK SECURITY GROUP (NSG)
##############################

# Creates a Network Security Group (NSG) for the Hub network
# This NSG controls inbound and outbound traffic flow for the Hub Virtual Network
resource "azurerm_network_security_group" "hub_nsg" {
  name                = "hub-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Security rule to allow VPN traffic between Hub and Spoke
  security_rule {
    name                       = "Allow-VPN-Spoke1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"  # Allows all protocols
    source_port_range          = "*"  # Allows traffic from any source port
    destination_port_range     = "*"  # Allows traffic to any destination port
    source_address_prefix      = "10.0.0.0/16"  # Traffic from Hub network
    destination_address_prefix = "10.1.0.0/16"  # Traffic to Spoke1 network
  }

  security_rule {
  name                       = "Allow-VPN-Spoke2"
  priority                   = 110  # Следующее по приоритету правило
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"  
  source_port_range          = "*"  
  destination_port_range     = "*"  
  source_address_prefix      = "10.0.0.0/16"  # Hub Network
  destination_address_prefix = "10.2.0.0/16"  # Spoke2 Network
}

  # Security rule to deny all inbound traffic by default
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"  # Blocks traffic from all sources
    destination_address_prefix = "*"  # Blocks traffic to all destinations
  }
}

##############################
# NSG ASSOCIATION TO SUBNET
##############################

# Associates the NSG with the Hub subnet
# This ensures that the defined security rules apply to the subnet
resource "azurerm_subnet_network_security_group_association" "hub_nsg_association" {
  subnet_id                 = azurerm_subnet.hub_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id

  lifecycle {
    ignore_changes = [network_security_group_id]  
  }
}