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
  administrator_login          = "adminuser"  # Admin username for SQL Server
  administrator_login_password = "P@ssword123!"  # Replace with a secure password
}

##############################
# ROLE-BASED ACCESS CONTROL (RBAC)
##############################

# Assigns the "SQL Server Contributor" role to a service principal
# This role allows managing databases, security, and configurations in SQL Server
resource "azurerm_role_assignment" "sql_admin_role" {
  scope                = azurerm_mssql_server.sql_server.id
  role_definition_name = "SQL Server Contributor"
  principal_id         = var.service_principal_object_id
}