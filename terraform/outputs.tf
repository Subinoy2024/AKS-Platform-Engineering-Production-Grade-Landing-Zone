output "resource_groups" {
  description = "Resource group names created by the platform."
  value = {
    hub      = module.rg_hub.name
    spoke    = module.rg_spoke.name
    aks      = module.rg_aks.name
    platform = module.rg_platform.name
  }
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "AKS cluster resource ID."
  value       = module.aks.cluster_id
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity."
  value       = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = module.acr.login_server
}

output "keyvault_uri" {
  description = "Key Vault URI."
  value       = module.keyvault.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID."
  value       = module.log_analytics.workspace_id
}

output "hub_vnet_id" {
  description = "Hub VNet ID."
  value       = module.networking.hub_vnet_id
}

output "spoke_vnet_id" {
  description = "Spoke VNet ID."
  value       = module.networking.spoke_vnet_id
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP (used as next hop)."
  value       = module.firewall.private_ip
}

output "deployment_summary" {
  description = "High-level deployment summary."
  value = {
    environment   = var.environment
    location      = var.location
    cluster       = module.aks.cluster_name
    private       = var.enable_private_cluster
    acr           = module.acr.login_server
    keyvault      = module.keyvault.vault_uri
    argocd_url    = "https://argocd.${var.environment}.${var.platform_name}.internal"
    grafana_url   = "https://grafana.${var.environment}.${var.platform_name}.internal"
  }
}
