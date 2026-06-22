resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_pod_subnet_contributor" {
  scope                = var.pod_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_private_dns" {
  count                = var.private_dns_zone_id == null ? 0 : 1
  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

####################################
# AKS Cluster
####################################

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  node_resource_group = var.node_resource_group
  dns_prefix          = "aks-${var.name_prefix}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"

  private_cluster_enabled             = var.private_cluster_enabled
  private_dns_zone_id                 = var.private_cluster_enabled ? var.private_dns_zone_id : null
  private_cluster_public_fqdn_enabled = false

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_policy_enabled      = true
  open_service_mesh_enabled = false
  image_cleaner_enabled     = true
  image_cleaner_interval_hours = 48

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool.vm_size
    vnet_subnet_id               = var.aks_subnet_id
    pod_subnet_id                = var.pod_subnet_id
    zones                        = var.system_node_pool.zones
    enable_auto_scaling          = true
    min_count                    = var.system_node_pool.min_count
    max_count                    = var.system_node_pool.max_count
    os_disk_size_gb              = var.system_node_pool.os_disk_size
    os_disk_type                 = "Managed"
    only_critical_addons_enabled = true
    type                         = "VirtualMachineScaleSets"
    max_pods                     = 50

    upgrade_settings {
      max_surge = "33%"
    }

    tags = var.tags
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    outbound_type       = "userDefinedRouting"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    pod_cidr            = "172.17.0.0/16"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "5m"
  }

  oms_agent {
    log_analytics_workspace_id      = var.workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  microsoft_defender {
    log_analytics_workspace_id = var.workspace_id
  }

  monitor_metrics {
    annotations_allowed = "*"
    labels_allowed      = "*"
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = "600"
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = "0.5"
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "04:00"
    utc_offset  = "+00:00"
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.aks_network_contributor,
    azurerm_role_assignment.aks_pod_subnet_contributor,
  ]

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }
}

####################################
# User node pool
####################################

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_pool.vm_size
  vnet_subnet_id        = var.aks_subnet_id
  pod_subnet_id         = var.pod_subnet_id
  zones                 = var.user_node_pool.zones
  enable_auto_scaling   = true
  min_count             = var.user_node_pool.min_count
  max_count             = var.user_node_pool.max_count
  os_disk_size_gb       = var.user_node_pool.os_disk_size
  os_disk_type          = "Managed"
  mode                  = "User"
  max_pods              = 80

  node_labels = {
    "workload-type" = "general"
  }

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

####################################
# Spot node pool (optional)
####################################

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                 = var.spot_node_pool.enabled ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.spot_node_pool.vm_size
  vnet_subnet_id        = var.aks_subnet_id
  pod_subnet_id         = var.pod_subnet_id
  zones                 = ["1", "2", "3"]
  enable_auto_scaling   = true
  min_count             = var.spot_node_pool.min_count
  max_count             = var.spot_node_pool.max_count
  os_disk_size_gb       = var.spot_node_pool.os_disk_size
  os_disk_type          = "Managed"
  mode                  = "User"
  priority              = "Spot"
  eviction_policy       = var.spot_node_pool.eviction_policy
  spot_max_price        = var.spot_node_pool.spot_max_price

  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "workload-type"                         = "spot"
  }

  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]

  tags = var.tags
}

####################################
# ACR pull
####################################

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

####################################
# Key Vault Secrets User
####################################

resource "azurerm_role_assignment" "aks_kv_user" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}

####################################
# Diagnostics
####################################

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-aks-${var.name_prefix}"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.workspace_id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "kube-scheduler" }
  enabled_log { category = "kube-audit-admin" }
  enabled_log { category = "cluster-autoscaler" }
  enabled_log { category = "guard" }

  metric { category = "AllMetrics" }
}
