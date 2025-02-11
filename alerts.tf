##############################
# ALERTING & MONITORING
##############################

# Creates an action group for critical alerts and notifications
# This resource is used to send notifications via email when alerts are triggered
resource "azurerm_monitor_action_group" "alert_group" {
  name                = "critical-alerts"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "alerts"
  location            = "global"

  # Defines an email recipient for alert notifications
  email_receiver {
    name          = "admin-email"
    email_address = var.alert_email  # Uses a variable instead of hardcoding
  }
}

##############################
# VPN MONITORING ALERT
##############################

# Defines a metric alert to monitor VPN tunnel connectivity
# This alert triggers a notification if the VPN tunnel is disconnected
resource "azurerm_monitor_metric_alert" "vpn_connection_alert" {
  name                = "vpn-disconnect-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_virtual_network_gateway.vpn_gw.id]
  description         = "Monitor VPN tunnel connectivity"
  severity            = 2  # Medium severity alert

  criteria {
    metric_namespace = "Microsoft.Network/virtualNetworkGateways"
    metric_name      = "TunnelTotalFlowCount"  # Monitors VPN tunnel flow count
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 1  # If no connections exist, the tunnel is considered disconnected
  }

  # Links the alert to the action group for notifications
  action {
    action_group_id = azurerm_monitor_action_group.alert_group.id
  }
}

##############################
# SQL SERVER STORAGE MONITORING ALERT
##############################

# Defines an alert to monitor Azure SQL Server storage utilization
# Triggers a notification if storage usage exceeds 80%
resource "azurerm_monitor_metric_alert" "sql_storage_alert" {
  name                = "sql-storage-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_mssql_server.sql_server.id]  # Monitors SQL Server
  description         = "Triggers an alert if SQL Server storage utilization exceeds 80%"
  severity            = 2  # Medium severity alert

  criteria {
    metric_namespace = "Microsoft.Sql/servers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80  # Triggers an alert if storage usage exceeds 80%
  }

  # Links the alert to the action group for notifications
  action {
    action_group_id = azurerm_monitor_action_group.alert_group.id
  }
}

##############################
# VARIABLES
##############################

# Variable for the alert email to avoid hardcoding
variable "alert_email" {
  description = "Email address for receiving alert notifications"
  type        = string
}