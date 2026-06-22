resource "azurerm_monitor_action_group" "platform" {
  name                = "ag-${var.name_prefix}-platform"
  resource_group_name = var.resource_group_name
  short_name          = "platag"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = toset(var.email_receivers)
    content {
      name          = "email-${replace(email_receiver.value, "@", "-at-")}"
      email_address = email_receiver.value
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.teams_webhook_url == "" ? [] : [var.teams_webhook_url]
    content {
      name        = "teams"
      service_uri = webhook_receiver.value
    }
  }
}

####################################
# Alerts on cluster
####################################

resource "azurerm_monitor_metric_alert" "node_cpu" {
  name                = "alert-${var.name_prefix}-node-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  description         = "Node CPU above 85% for 15 minutes"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.platform.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "node_memory" {
  name                = "alert-${var.name_prefix}-node-memory"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  description         = "Node memory above 85% for 15 minutes"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.platform.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "pod_ready" {
  name                = "alert-${var.name_prefix}-pod-not-ready"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  description         = "Pods stuck in not-ready state"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_pod_status_ready"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.platform.id
  }

  tags = var.tags
}
