output "containers" {
  value = azurerm_storage_container.domino_containers
}

output "kubeconfig" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "resource_group" {
  value = local.resource_group
}

output "storage_account" {
  value = azurerm_storage_account.domino
}
