# This is the previous service princiapal code that we tried to deprecate for managed identities
# Unfortunately, we seem to be unable to provision public load balancers since the change
# Assume there's a way around this, yet need to land this ASAP, so cordoning this off ito this
# file. We should fix the issue with the managed identity and nuke all this.

data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
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

  provisioner "local-exec" {
    command = "sleep 15"
  }

  tags = [local.cluster_name]
}

resource "azuread_service_principal_password" "sp" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_password.aks.result
  end_date             = "2099-01-01T01:00:00Z"

  provisioner "local-exec" {
    command = "sleep 15"
  }
}

resource "azurerm_role_assignment" "sp" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.sp.object_id
}

variable subscription_id {
  type        = string
  description = "An existing Subscription ID to add the deployment"
  default     = ""
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}
