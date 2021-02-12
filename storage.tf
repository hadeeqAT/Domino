resource "azurerm_storage_account" "domino" {
  name                     = local.storage_account_name
  resource_group_name      = local.resource_group.name
  location                 = local.resource_group.location
  account_kind             = "StorageV2"
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  access_tier              = "Hot"
  tags                     = local.tags
}

resource "azurerm_storage_container" "domino_containers" {
  for_each = {
    for key, value in var.containers :
    key => value
  }

  name                  = substr("${local.cluster_name}-${each.key}", 0, 63)
  storage_account_name  = azurerm_storage_account.domino.name
  container_access_type = each.value.container_access_type

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}
