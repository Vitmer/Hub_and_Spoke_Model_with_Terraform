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

# Creates a DDoS Protection Plan for enhanced network security
resource "azurerm_network_ddos_protection_plan" "ddos_plan" {
  name                = "ddos-protection"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

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

##############################
# PRIVATE ENDPOINTS
##############################

# Creates a private endpoint for secure Key Vault access
resource "azurerm_private_endpoint" "kv_private" {
  name                = "kv-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_link_subnet.id

  private_service_connection {
    name                           = "kv-private-connection"
    private_connection_resource_id = azurerm_key_vault.vault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

##############################
# DATABASE CONFIGURATION
##############################

# Creates an Azure SQL Server instance
resource "azurerm_mssql_server" "example" {
  name                         = "sql-server-example"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "adminuser"
  administrator_login_password = "P@ssword123!"
}

##############################
# VIRTUAL WAN
##############################

# Creates a Virtual WAN for centralized networking and security management
resource "azurerm_virtual_wan" "main_vwan" {
  name                = "main-vwan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  type                = "Standard"
}

# Creates a Virtual HUB for centralized networking and security management
/*resource "azurerm_virtual_hub" "hub" {
  name                = "virtual-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  address_prefix      = "10.5.0.0/24"  # CIDR Virtual Hub
}*/


##############################
# LOG ANALYTICS WORKSPACES
##############################

# Creates a Log Analytics workspace for monitoring and security insights
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-workspace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}