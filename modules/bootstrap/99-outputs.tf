output "resource_group_name" {
  value = azurerm_storage_account.this.resource_group_name
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "private_endpoint_id" {
  value = try(azurerm_private_endpoint.this[0].id, null)
}

output "group_object_id" {
  value = local.group_object_id
}
