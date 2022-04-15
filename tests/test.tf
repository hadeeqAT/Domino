terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "dominoterraform"
    storage_account_name = "dominoterraformstorage"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "api_server_authorized_ip_ranges" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

resource "azurerm_resource_group" "ci" {
  name     = terraform.workspace
  location = "westus2"
  tags     = var.tags
}

module "aks" {
  source = "./.."

  cluster_name                    = terraform.workspace
  resource_group                  = azurerm_resource_group.ci.id
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  tags                            = var.tags
  kubeconfig_output_path          = "${path.cwd}/kubeconfig"
}
