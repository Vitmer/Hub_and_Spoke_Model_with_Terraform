##############################
# KEY VAULT CONFIGURATION
##############################

# Creates an Azure Key Vault for secure secret storage
resource "azurerm_key_vault" "vault" {
  name                = "secure-keyvault-${random_id.kv_suffix.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
}

# Generates a random suffix for the Key Vault name to ensure uniqueness
resource "random_id" "kv_suffix" {
  byte_length = 4
}

# Stores the service principal key inside Azure Key Vault as a secret
resource "azurerm_key_vault_secret" "service_principal_key" {
  name         = "terraform-sp-key"
  value        = var.service_principal_key
  key_vault_id = azurerm_key_vault.vault.id
}

# Assigns access policy for secure access to the Key Vault
resource "azurerm_key_vault_access_policy" "secure_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = var.tenant_id
  object_id    = var.service_principal_id

  key_permissions = [
    "Get", "List", "Update"
  ]

  secret_permissions = [
    "Get", "List"
  ]
}

# Assigns full administrative permissions to an additional user or service principal
resource "azurerm_key_vault_access_policy" "admin_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = var.tenant_id
  object_id    = var.service_principal_object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Delete"
  ]
  secret_permissions = [
    "Get", "List", "Set"
  ]
}

##############################
# SECURITY & DDOS PROTECTION
##############################

/*# Creates a DDoS Protection Plan for enhanced network security
resource "azurerm_network_ddos_protection_plan" "ddos_plan" {
  name                = "ddos-protection"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}*/

##############################
# ROLE-BASED ACCESS CONTROL (RBAC)
##############################

# Assigns a "Reader" role to a service principal for read-only access to the resource group
resource "azurerm_role_assignment" "read_only_access" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = var.service_principal_object_id
}

# Assigns a "Network Contributor" role for limited administrative access to the Virtual Network
resource "azurerm_role_assignment" "limited_admin" {
  scope                = azurerm_virtual_network.hub_vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = var.service_principal_object_id
}

# Assigns the "SQL Server Contributor" role to a service principal
# This role allows managing databases, security, and configurations in SQL Server
resource "azurerm_role_assignment" "sql_admin_role" {
  scope                = azurerm_mssql_server.sql_server.id
  role_definition_name = "SQL Server Contributor"
  principal_id         = var.service_principal_object_id
}

# Assigns the "User Access Administrator" role to a service principal
# This allows managing role assignments and access permissions
resource "azurerm_role_assignment" "user_access_admin" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "User Access Administrator"
  principal_id         = var.service_principal_object_id
}
