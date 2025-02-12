##############################
# SQL SERVER CONFIGURATION
##############################

# Creates an Azure SQL Server with a secure configuration
# This resource is used to host and manage SQL databases in Azure
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-server-secure"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"  # Specifies SQL Server version
  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password
}
