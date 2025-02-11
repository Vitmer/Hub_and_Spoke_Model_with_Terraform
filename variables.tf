variable "subscription_id" {
  description = "The subscription ID where Azure resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where all resources will reside"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}
variable "service_principal_key" {
  description = "Service principal key for accessing Azure resources"
  type        = string
  sensitive   = true
}
variable "rbac_principal_id" {
  description = "Principal ID for RBAC roles"
  type        = string
}
variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "service_principal_id" {
  description = "Service Principal ID used for RBAC"
  type        = string
}
variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}
variable "data_factory_name" {
  description = "The name of the Azure Data Factory instance"
  type        = string
}
variable "synapse_sql_password" {
  description = "Password for Synapse SQL administrator"
  type        = string
  sensitive   = true
}

variable "enable_prevent_destroy" {
  description = "Enable or disable the prevent_destroy lifecycle for resources"
  type        = bool
  default     = true
}
variable "service_principal_object_id" {
  description = "Object ID of the Service Principal"
  type        = string
}
## Variable for the alert email to avoid hardcoding
variable "alert_email" {
  description = "Email address for receiving alert notifications"
  type        = string
  default     = "admin@example.com"  # Default email for alerts
}