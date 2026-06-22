resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_container_registry" "this" {
  name                = "acr${replace(var.name_prefix, "-", "")}${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Premium"
  admin_enabled       = false

  public_network_access_enabled = false
  zone_redundancy_enabled       = true
  retention_policy {
    days    = 30
    enabled = true
  }

  trust_policy {
    enabled = true
  }

  dynamic "georeplications" {
    for_each = toset(var.geo_replication_locations)
    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
      tags                    = var.tags
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_container_registry_scope_map" "ci_push" {
  name                    = "scope-ci-push"
  container_registry_name = azurerm_container_registry.this.name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/*/content/write",
    "repositories/*/content/read",
    "repositories/*/metadata/read",
  ]
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${azurerm_container_registry.this.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "diag-${azurerm_container_registry.this.name}"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "ContainerRegistryRepositoryEvents" }
  enabled_log { category = "ContainerRegistryLoginEvents" }
  metric { category = "AllMetrics" }
}
