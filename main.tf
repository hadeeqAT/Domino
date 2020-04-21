provider "azurerm" {
  version = ">=2.3.0"
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "dominoterraform"
    storage_account_name = "dominoterraformstorage"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

locals {
  cluster_name = var.cluster_name != null ? var.cluster_name : terraform.workspace
}

data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "k8s" {
  name     = local.cluster_name
  location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "logs" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.log_analytics_workspace_location
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "logs" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.logs.location
  resource_group_name   = azurerm_resource_group.k8s.name
  workspace_resource_id = azurerm_log_analytics_workspace.logs.id
  workspace_name        = azurerm_log_analytics_workspace.logs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azuread_application" "app" {
  name = local.cluster_name


  app_role {
    allowed_member_types = [
      "User",
      "Application",
    ]

    description  = "Admins can manage roles and perform all task actions"
    display_name = "Admin"
    is_enabled   = true
    value        = "Admin"
  }
}

resource "random_password" "aks" {
  length  = 24
  special = true
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.app.application_id

  tags = [local.cluster_name]
}

resource "azuread_service_principal_password" "sp" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_password.aks.result
  end_date             = "2099-01-01T01:00:00Z"
}

resource "azurerm_role_assignment" "sp" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.sp.object_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  name                       = local.cluster_name
  enable_pod_security_policy = false
  location                   = azurerm_resource_group.k8s.location
  resource_group_name        = azurerm_resource_group.k8s.name
  dns_prefix                 = local.cluster_name
  private_link_enabled       = false

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  default_node_pool {
    enable_node_public_ip = var.node_pools.platform.enable_node_public_ip
    name                  = "platform"
    node_count            = var.node_pools.platform.max_count
    node_labels           = merge({ "dominodatalab.com/node-pool" : "platform" }, var.node_pools.platform.node_labels)
    vm_size               = var.node_pools.platform.vm_size
    availability_zones    = var.node_pools.platform.zones
    max_pods              = 250
    os_disk_size_gb       = 128
    node_taints           = var.node_pools.platform.node_taints
    enable_auto_scaling   = var.node_pools.platform.enable_auto_scaling
    min_count             = var.node_pools.platform.min_count
    max_count             = var.node_pools.platform.max_count
    tags                  = {}
  }

  service_principal {
    client_id     = azuread_service_principal.sp.application_id
    client_secret = azuread_service_principal_password.sp.value
  }

  addon_profile {
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

  tags = {
    Environment = "Development"
  }

}

resource "azurerm_kubernetes_cluster_node_pool" "aks" {
  lifecycle {
    ignore_changes = [
      node_count
    ]
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
  node_count            = each.value.max_count
  vm_size               = each.value.vm_size
  availability_zones    = each.value.zones
  max_pods              = 250
  os_disk_size_gb       = 128
  os_type               = each.value.node_os
  node_labels           = merge({ "dominodatalab.com/node-pool" : each.key }, each.value.node_labels)
  node_taints           = each.value.node_taints
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  tags                  = {}
}
