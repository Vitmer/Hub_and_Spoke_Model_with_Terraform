##############################
# SECURITY - FIREWALL & ROUTING
##############################

# Creates an Azure Firewall Policy
resource "azurerm_firewall_policy" "hub_firewall_policy" {
  name                = "hub-firewall-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

}

resource "azurerm_firewall_policy_rule_collection_group" "hub_firewall_rules" {
  name               = "hub-firewall-rules"
  firewall_policy_id = azurerm_firewall_policy.hub_firewall_policy.id
  priority           = 100

  network_rule_collection {
    name     = "Allow-Internet"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "AllowHTTPs"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "AllowSSH"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["22"]
    }

    rule {
      name                  = "AllowRDP"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["3389"]
    }

    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "AllowICMP"
      protocols             = ["ICMP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }
}


# Deploys Azure Firewall in the Hub network
resource "azurerm_firewall" "hub_firewall" {
  name                = "hub-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  firewall_policy_id  = azurerm_firewall_policy.hub_firewall_policy.id

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

# Default route: Forward all traffic to Firewall
resource "azurerm_route" "default_route" {
  name                   = "all-traffic-to-firewall"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub_route_table.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
}

# Associating the Route Table with the Hub Subnet  
# This resource links the Hub Route Table to the Hub Subnet, ensuring all traffic follows the defined routing rules.
resource "azurerm_subnet_route_table_association" "hub_route_assoc" {
  subnet_id      = azurerm_subnet.hub_subnet.id
  route_table_id = azurerm_route_table.hub_route_table.id
}


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