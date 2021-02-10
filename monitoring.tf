resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "logs" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = "${local.resource_group.name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = var.log_analytics_workspace_sku
  tags                = var.tags
}

resource "azurerm_log_analytics_solution" "logs" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.logs.location
  resource_group_name   = local.resource_group.name
  workspace_resource_id = azurerm_log_analytics_workspace.logs.id
  workspace_name        = azurerm_log_analytics_workspace.logs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "control-plane" {
  name                       = "AKS Control Plane Logging"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  log {
    category = "kube-apiserver"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "kube-controller-manager"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "kube-scheduler"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "cluster-autoscaler"

    retention_policy {
      enabled = true
      days    = 7
    }
  }
}
