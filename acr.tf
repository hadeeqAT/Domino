resource "azurerm_container_registry" "domino" {
  name                = replace("${data.azurerm_resource_group.aks.name}domino", "/[^a-zA-Z0-9]/", "")
  resource_group_name = data.azurerm_resource_group.aks.name
  location            = data.azurerm_resource_group.aks.location

  sku           = var.registry_tier
  admin_enabled = false

  # Premium only
  public_network_access_enabled = var.registry_tier == "Premium" ? false : true

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_domino_acr" {
  scope                = azurerm_container_registry.domino.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
