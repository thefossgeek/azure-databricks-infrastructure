variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the storage account"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "create_resource_group" {
  type        = bool
  description = "Create the resource group, or use an existing one"
  default     = true
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name"
}

variable "replication_type" {
  type        = string
  description = "Storage replication type (LRS/ZRS/GRS/GZRS)"
  default     = "LRS"
}

variable "container_names" {
  type        = list(string)
  description = "Blob containers to create"
}

variable "create_group" {
  type        = bool
  description = "Create the Entra ID group and manage owners/members. If false, look up an existing group by display_name instead — no create, no membership changes."
  default     = true
}

variable "group_display_name" {
  type        = string
  description = "Entra ID security group name, granted Storage Blob Data Contributor. Created when create_group is true, looked up when false."
}

variable "group_description" {
  type        = string
  description = "Description shown on the Entra ID group. Only used when create_group is true."
  default     = null
}

variable "group_owner_upns" {
  type        = list(string)
  description = "User principal names of group owners. Only used when create_group is true."
  default     = []
}

variable "group_member_upns" {
  type        = list(string)
  description = "User principal names of group members. Only used when create_group is true."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
}

variable "sas_expiration_period" {
  type        = string
  description = "Max lifetime for any SAS token, as DD.HH:MM:SS"
  default     = "7.00:00:00"
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs allowed via service endpoint, in addition to the private endpoint"
  default     = []
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Day 2: create the private endpoint and close public access"
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Existing subnet for the private endpoint NIC (required when enable_private_endpoint is true)"
  default     = null
}

variable "private_dns_zone_id" {
  type        = string
  description = "Existing privatelink.blob.core.windows.net zone, already linked to the VNet (required when enable_private_endpoint is true)"
  default     = null
}

variable "enable_diagnostics" {
  type        = bool
  description = "Day 2: send blob read/write/delete logs and transaction metrics to Log Analytics"
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Existing Log Analytics workspace resource ID (required when enable_diagnostics is true)"
  default     = null
}
