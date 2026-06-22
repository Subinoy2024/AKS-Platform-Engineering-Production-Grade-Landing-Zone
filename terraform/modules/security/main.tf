####################################
# Microsoft Defender for Cloud
####################################

resource "azurerm_security_center_subscription_pricing" "defender_containers" {
  tier          = "Standard"
  resource_type = "Containers"
}

resource "azurerm_security_center_subscription_pricing" "defender_keyvaults" {
  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "defender_appservices" {
  tier          = "Standard"
  resource_type = "AppServices"
}

resource "azurerm_security_center_auto_provisioning" "this" {
  auto_provision = "On"
}

resource "azurerm_security_center_workspace" "this" {
  scope        = "/subscriptions/${var.subscription_id}"
  workspace_id = var.log_analytics_id
}

####################################
# Security contact
####################################

resource "azurerm_security_center_contact" "this" {
  name                = "platform-security"
  email               = "security@example.com"
  alert_notifications = true
  alerts_to_admins    = true
}
