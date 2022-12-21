terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "6d2e3a80-7b47-4bab-a829-b4f4e73a77f5"
  features {}

}


module "domino-aks" {
  source                          = "github.com/dominodatalab/terraform-azure-aks"
  api_server_authorized_ip_ranges = null
  resource_group                  = "MSA_Domino_PoC"
  deploy_id                       = "domino-aks-custer"
  kubeconfig_output_path          = "./config/config"
  kubernetes_version              = "1.22.6"


  node_pools = {
    compute = {
      enable_node_public_ip = false
      vm_size               = "Standard_DS8_v2"
      zones                 = ["1"]
      node_labels = {
        "dominodatalab.com/node-pool" = "default"
      }
      node_os             = "Linux"
      node_taints         = []
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 10
      initial_count       = 3
      max_pods            = 30
      os_disk_size_gb     = 128
    } 
    /*
    gpu = {
      enable_node_public_ip = false
      vm_size               = "Standard_NC6s_v3"
      zones                 = []
      node_labels = {
        "dominodatalab.com/node-pool" = "default-gpu"
        "nvidia.com/gpu"              = "true"
      }
      node_os = "Linux"
      node_taints = [
        "nvidia.com/gpu=true:NoExecute"
      ]
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 1
      initial_count       = 0
      max_pods            = 30
      os_disk_size_gb     = 128
    }
    */
    platform = {
      enable_node_public_ip = false
      vm_size               = "Standard_DS5_v2"
      zones                 = ["1"]
      node_labels = {
        "dominodatalab.com/node-pool" = "platform"
      }
      node_os             = "Linux"
      node_taints         = []
      enable_auto_scaling = true
      min_count           = 4
      max_count           = 4
      initial_count       = 4
      max_pods            = 60
      os_disk_size_gb     = 128
    }
  }
}
