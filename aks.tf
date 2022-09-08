locals {
  node_pools = {
    for node_pool, attrs in var.node_pools :
    node_pool => merge(attrs, lookup(var.node_pool_overrides, node_pool, {}))
  }

  zonal_node_pools = flatten([for name, spec in local.node_pools : [
    for zone in spec.zones :
    {
      node_pool_zone = zone
      node_pool_name = name
      node_pool_spec = spec
    }
    ]
  ])
}

data "azurerm_kubernetes_service_versions" "selected" {
  location       = data.azurerm_resource_group.aks.location
  version_prefix = var.kubernetes_version
}

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

  name                    = var.deploy_id
  location                = data.azurerm_resource_group.aks.location
  resource_group_name     = data.azurerm_resource_group.aks.name
  dns_prefix              = var.deploy_id
  private_cluster_enabled = false
  sku_tier                = var.cluster_sku_tier
  kubernetes_version      = data.azurerm_kubernetes_service_versions.selected.latest_version

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  default_node_pool {
    enable_node_public_ip        = false
    only_critical_addons_enabled = true
    name                         = "system"
    node_count                   = 1
    vm_size                      = "standard_ds4_v2"
    zones                        = ["1", "2", "3"]
    os_disk_size_gb              = 128
    enable_auto_scaling          = true
    min_count                    = 1
    max_count                    = 6
    max_pods                     = 60
    tags                         = var.tags
  }
  identity {
    type = "SystemAssigned"
  }


  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "azure"
    network_policy    = "calico"
  }

  tags = var.tags

  provisioner "local-exec" {
    command = <<-EOF
      if ! az account show 2>/dev/null; then
        az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET -t $ARM_TENANT_ID
      fi

      az aks get-credentials --overwrite-existing -f ${var.kubeconfig_output_path} -n ${var.deploy_id} -g ${data.azurerm_resource_group.aks.name}
    EOF
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "aks" {
  for_each = { for ng in local.zonal_node_pools : "${ng.node_pool_name}${ng.node_pool_zone}" => ng }

  enable_node_public_ip = each.value.node_pool_spec.enable_node_public_ip
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = each.key
  node_count            = each.value.node_pool_spec.initial_count
  vm_size               = each.value.node_pool_spec.vm_size
  zones                 = [each.value.node_pool_zone]
  os_disk_size_gb       = each.value.node_pool_spec.os_disk_size_gb
  os_type               = each.value.node_pool_spec.node_os
  node_labels           = each.value.node_pool_spec.node_labels
  node_taints           = each.value.node_pool_spec.node_taints
  enable_auto_scaling   = each.value.node_pool_spec.enable_auto_scaling
  min_count             = each.value.node_pool_spec.min_count
  max_count             = each.value.node_pool_spec.max_count
  max_pods              = each.value.node_pool_spec.max_pods
  tags                  = var.tags

  lifecycle {
    ignore_changes = [node_count, max_count, tags]
  }

}
