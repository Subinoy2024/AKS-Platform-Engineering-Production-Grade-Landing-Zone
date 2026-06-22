####################################
# Azure Policy assignments for AKS baseline
####################################

resource "azurerm_subscription_policy_assignment" "k8s_baseline" {
  name                 = "policy-${var.name_prefix}-aks-baseline"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  display_name         = "AKS Baseline Cluster Standards - ${var.environment}"
  description          = "Enforces baseline cluster security standards"
  enforce              = var.environment == "prod"

  parameters = jsonencode({
    effect = {
      value = var.environment == "prod" ? "deny" : "audit"
    }
  })

  identity {
    type = "SystemAssigned"
  }

  location = "eastus2"
}

####################################
# Required tags policy
####################################

resource "azurerm_policy_definition" "require_tags" {
  name         = "require-platform-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Platform Tags"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['Environment']", exists = "false" },
        { field = "tags['Owner']", exists = "false" },
        { field = "tags['CostCenter']", exists = "false" }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "assign-require-tags"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  display_name         = "Require Platform Tags"
}

####################################
# Built-in: allowed locations
####################################

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  display_name         = "Allowed locations"
  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["eastus2", "centralus", "westus2"]
    }
  })
}
