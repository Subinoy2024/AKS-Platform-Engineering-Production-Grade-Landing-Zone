resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

####################################
# Storage account for Velero backups
####################################

resource "azurerm_storage_account" "velero" {
  name                     = "stvelero${replace(var.name_prefix, "-", "")}${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
    versioning_enabled = true
  }

  tags = var.tags
}

resource "azurerm_storage_container" "velero" {
  name                  = "velero"
  storage_account_name  = azurerm_storage_account.velero.name
  container_access_type = "private"
}

####################################
# Recovery Services Vault
####################################

resource "azurerm_recovery_services_vault" "this" {
  name                = "rsv-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  soft_delete_enabled = true
  storage_mode_type   = "GeoRedundant"
  tags                = var.tags
}
