locals {
  zones = {
    aks  = "privatelink.${var.location}.azmk8s.io"
    acr  = "privatelink.azurecr.io"
    kv   = "privatelink.vaultcore.azure.net"
    blob = "privatelink.blob.core.windows.net"
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.zones
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  for_each              = local.zones
  name                  = "link-spoke-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each              = local.zones
  name                  = "link-hub-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}
