data "azuread_users" "owners" {
  count                = var.create_group ? 1 : 0
  user_principal_names = var.group_owner_upns
}

data "azuread_users" "members" {
  count                = var.create_group ? 1 : 0
  user_principal_names = var.group_member_upns
}

# Owners must include whoever/whatever runs Terraform, or later applies that
# change membership can fail with insufficient permissions on the group.
resource "azuread_group" "this" {
  count = var.create_group ? 1 : 0

  display_name     = var.group_display_name
  description      = var.group_description
  security_enabled = true
  owners           = data.azuread_users.owners[0].users[*].object_id
  members          = data.azuread_users.members[0].users[*].object_id
}

# create_group = false: group already exists and is managed outside this
# module — look it up, don't touch its membership.
data "azuread_group" "this" {
  count        = var.create_group ? 0 : 1
  display_name = var.group_display_name
}

locals {
  group_object_id = var.create_group ? azuread_group.this[0].object_id : data.azuread_group.this[0].object_id
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags

  lifecycle {
    ignore_changes = [tags["owner"]]
  }
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name

  depends_on = [azurerm_resource_group.this]
}

# Independent of the storage account lock below, protects everything else in the RG.
resource "azurerm_management_lock" "resource_group" {
  count      = var.create_resource_group ? 1 : 0
  name       = "delete-lock"
  scope      = azurerm_resource_group.this[0].id
  lock_level = "CanNotDelete"
  notes      = "Managed by Terraform, must not be deleted"
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  tags                     = var.tags

  allow_nested_items_to_be_public  = false
  https_traffic_only_enabled       = true
  shared_access_key_enabled        = false
  cross_tenant_replication_enabled = false
  local_user_enabled               = false
  default_to_oauth_authentication  = true
  public_network_access            = var.enable_private_endpoint ? "Disabled" : "Enabled"

  # Double encryption at rest: platform-managed key + a second infrastructure-layer key
  infrastructure_encryption_enabled = true

  # Blocks Copy Blob to/from accounts outside this AAD tenant (exfiltration path);
  # tightens to same-private-network-only once the private endpoint is enabled
  allowed_copy_scope = var.enable_private_endpoint ? "PrivateLink" : "AAD"

  # Bounds how long any Azure AD user-delegation SAS token can be valid, since
  # shared_access_key_enabled = false already rules out account-key SAS
  sas_policy {
    expiration_period = var.sas_expiration_period
    expiration_action = "Block"
  }

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true
    delete_retention_policy {
      days = 32
    }
    container_delete_retention_policy {
      days = 32
    }
    restore_policy {
      days = 30
    }
  }

  lifecycle {
    ignore_changes = [tags["owner"]]
  }
}

# Split out from azurerm_storage_account: the inline network_rules block has a
# known provider bug where default_action = "Allow" never reads back into
# state, causing a perpetual plan diff. This resource doesn't have that issue.
resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id         = azurerm_storage_account.this.id
  default_action             = var.enable_private_endpoint ? "Deny" : "Allow"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = var.allowed_subnet_ids
}

# Travels with the account even if it's ever moved out of this resource group.
resource "azurerm_management_lock" "storage_account" {
  name       = "delete-lock"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Terraform state backend, must not be deleted"
}

resource "azurerm_storage_container" "this" {
  for_each = toset(var.container_names)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"

  # azurerm_private_endpoint.this may be a no-op (count = 0) on Day 1; when it
  # does exist, containers must not race the network lockdown to reach it.
  depends_on = [azurerm_role_assignment.this, azurerm_private_endpoint.this, azurerm_storage_account_network_rules.this]
}

resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  lifecycle {
    ignore_changes = [tags["owner"]]
  }
}

# No dedicated resource for blob service properties (blob_properties is inline
# above), so the sub-resource ID is built by hand — this is the standard way to
# target storage's blobServices/default for diagnostic settings in Terraform.
resource "azurerm_monitor_diagnostic_setting" "blob" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "${var.storage_account_name}-blob-diag"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}

resource "azurerm_role_assignment" "this" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.group_object_id
}
