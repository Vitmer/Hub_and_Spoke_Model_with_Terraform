##############################
# PRIVATE ENDPOINTS
##############################

# Create a Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "privatedns_sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private DNS Zone to the virtual network (Hub)
resource "azurerm_private_dns_zone_virtual_network_link" "link_sql" {
  name                  = "sql-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatedns_sql.name
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
}

# Creating a Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "private_sql" {
  name                = "private-sql-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_link_subnet.id  # Subnet for Private Link

  private_service_connection {
    name                           = "private-sql-connection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id  # Linking to SQL Server
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]  # Connecting specifically to SQL Server
  }
}

# Associate the Private Endpoint with the Private DNS
resource "azurerm_private_dns_a_record" "private_sql_dns" {
  name                = azurerm_mssql_server.sql_server.name
  zone_name           = azurerm_private_dns_zone.privatedns_sql.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.private_sql.private_service_connection[0].private_ip_address]
}