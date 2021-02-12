resource "azurerm_kubernetes_cluster" "aks" {
  lifecycle {
    ignore_changes = [
      tags,
      default_node_pool[0].node_count,
      default_node_pool[0].max_count,
      default_node_pool[0].tags,
      # VM Size changes cause recreation of the entire cluster
      default_node_pool[0].vm_size
    ]
  }

  name                    = local.cluster_name
  location                = local.resource_group.location
  resource_group_name     = local.resource_group.name
  dns_prefix              = local.cluster_name
  private_cluster_enabled = false
  sku_tier                = var.cluster_sku_tier

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  default_node_pool {
    enable_node_public_ip = var.node_pools.platform.enable_node_public_ip
    name                  = "platform"
    node_count            = var.node_pools.platform.min_count
    node_labels           = var.node_pools.platform.node_labels
    vm_size               = var.node_pools.platform.vm_size
    availability_zones    = var.node_pools.platform.zones
    os_disk_size_gb       = var.node_pools.platform.os_disk_size_gb
    node_taints           = var.node_pools.platform.node_taints
    enable_auto_scaling   = var.node_pools.platform.enable_auto_scaling
    min_count             = var.node_pools.platform.min_count
    max_count             = var.node_pools.platform.max_count
    max_pods              = var.node_pools.platform.max_pods
    tags                  = local.tags
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
    }
  }

  network_profile {
    load_balancer_sku  = "Standard"
    network_plugin     = "azure"
    network_policy     = "calico"
    dns_service_ip     = "100.97.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "100.97.0.0/16"
  }

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "aks" {
  lifecycle {
    ignore_changes = [node_count, max_count]
  }

  for_each = {
    # Create all node pools except for 'platform' because it is the AKS default
    for key, value in var.node_pools :
    key => value
    if key != "platform"
  }

  enable_node_public_ip = each.value.enable_node_public_ip
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = each.key
  node_count            = each.value.min_count
  vm_size               = each.value.vm_size
  availability_zones    = each.value.zones
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_type               = each.value.node_os
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  max_pods              = each.value.max_pods
  tags                  = local.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}
