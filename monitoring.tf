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

##############################
# LOGGING & MONITORING
##############################

# Diagnostic settings for Azure Firewall logs
# This resource enables logging of firewall network and application rules in Log Analytics
resource "azurerm_monitor_diagnostic_setting" "firewall_logs" {
  name                       = "firewall-logs"
  target_resource_id         = azurerm_firewall.hub_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Virtual Network logs
# This resource enables logging of network protection alerts for VNet in Log Analytics
resource "azurerm_monitor_diagnostic_setting" "vnet_logs" {
  name                       = "vnet-monitor-logs"
  target_resource_id         = azurerm_virtual_network.hub_vnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Virtual Hub logs
# Enables monitoring and logging for the Hub Virtual Network
resource "azurerm_monitor_diagnostic_setting" "hub_logs" {
  name                       = "hub-logs"
  target_resource_id         = azurerm_virtual_network.hub_vnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
  }
}

##############################
# AZURE SENTINEL CONFIGURATION
##############################

# Onboarding Azure Sentinel with Log Analytics
# This resource integrates the Log Analytics workspace with Azure Sentinel for security monitoring
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.logs.id
}

# Creates a high-severity security alert rule in Azure Sentinel
# Triggers alerts when Microsoft Cloud App Security detects suspicious activity
resource "azurerm_sentinel_alert_rule_ms_security_incident" "security_alert" {
  name                        = "suspicious-activity-alert"
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.security_logs.id
  display_name                = "Suspicious Activity Alert"
  enabled                     = true
  product_filter              = "Microsoft Cloud App Security"
  severity_filter             = ["High"]
}

##############################
# LOG ANALYTICS WORKSPACES
##############################

# Creates a Log Analytics workspace for storing security logs
# Used for threat detection, monitoring, and compliance reporting
resource "azurerm_log_analytics_workspace" "security_logs" {
  name                = "security-log-workspace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

##############################
# IDENTITY MANAGEMENT
##############################

# Creates a user-assigned managed identity for SQL Server
# This identity can be used for secure authentication and role-based access control
resource "azurerm_user_assigned_identity" "sql_admin" {
  name                = "sql-admin-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}