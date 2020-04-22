output "kubeconfig" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}
