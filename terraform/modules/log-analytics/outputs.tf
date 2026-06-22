output "workspace_id" { value = azurerm_log_analytics_workspace.this.id }
output "workspace_customer_id" { value = azurerm_log_analytics_workspace.this.workspace_id }
output "primary_shared_key" {
  value     = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive = true
}
output "monitor_workspace_id" { value = azurerm_monitor_workspace.prometheus.id }
output "grafana_endpoint" { value = azurerm_dashboard_grafana.this.endpoint }
output "grafana_id" { value = azurerm_dashboard_grafana.this.id }
