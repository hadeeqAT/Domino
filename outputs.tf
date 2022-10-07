output "containers" {
  description = "storage details"
  value       = azurerm_storage_container.domino_containers
}

output "storage_account" {
  description = "storage account"
  value       = azurerm_storage_account.domino
}

output "aks_identity" {
  description = "AKS managed identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0]
}

output "domino_acr" {
  description = "Azure Container Registry details"
  value       = azurerm_container_registry.domino
}
