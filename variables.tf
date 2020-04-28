

variable "agent_count" {
  default = 3
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "The IP ranges to whitelist for incoming traffic to the masters"
}

variable "cluster_name" {
  type        = string
  default     = null
  description = "The Domino cluster name for the K8s cluster and resource group"
}

variable "location" {
  default = "West US 2"
}

variable "log_analytics_workspace_name" {
  default = "testLogAnalyticsWorkspaceName"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable "log_analytics_workspace_location" {
  default = "eastus"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable "log_analytics_workspace_sku" {
  default = "PerGB2018"
}

variable "node_pools" {
  type = map(object({
    enable_node_public_ip = bool
    vm_size               = string
    zones                 = list(string)
    node_labels           = map(string)
    node_os               = string
    node_taints           = list(string)
    enable_auto_scaling   = bool
    min_count             = number
    max_count             = number
  }))
  default = {
    compute = {
      enable_node_public_ip = false
      vm_size               = "Standard_DS4_v2"
      zones                 = ["1", "2", "3"]
      node_labels = {
        "domino/build-node"            = "true"
        "dominodatalab.com/build-node" = "true"
        "dominodatalab.com/node-pool"  = "default"
      }
      node_os             = "Linux"
      node_taints         = []
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 4
    }
    # Example GPU Configuration
    # gpu = {
    #   vm_size = "Standard_DS3_v2"
    #   zones   = ["1", "2", "3"]
    #   node_labels = {
    #     "dominodatalab.com/node-pool" = "default-gpu"
    #     "nvidia.com/gpu"              = "true"
    #   }
    #   node_os = "Linux"
    #   node_taints = [
    #     "nvidia.com/gpu=true"
    #   ]
    #   enable_auto_scaling = true
    #   min_count           = 1
    #   max_count           = 1
    # }
    platform = {
      enable_node_public_ip = false
      vm_size               = "Standard_DS5_v2"
      zones                 = ["1", "2", "3"]
      node_labels           = {}
      node_os               = "Linux"
      node_taints           = []
      enable_auto_scaling   = true
      min_count             = 1
      max_count             = 4
    }
  }
}
