output "aks_zone_id" { value = azurerm_private_dns_zone.this["aks"].id }
output "acr_zone_id" { value = azurerm_private_dns_zone.this["acr"].id }
output "kv_zone_id" { value = azurerm_private_dns_zone.this["kv"].id }
output "blob_zone_id" { value = azurerm_private_dns_zone.this["blob"].id }
