####################################
# Locals - naming standards & tags
####################################

locals {
  name_prefix = "${var.platform_name}-${var.environment}"

  default_tags = {
    Platform      = "AKS-Platform-Engineering"
    Environment   = var.environment
    ManagedBy     = "Terraform"
    Owner         = "PlatformTeam"
    CostCenter    = "Engineering"
    BusinessUnit  = "CloudPlatform"
    Compliance    = "ISO27001"
    DataClass     = "Internal"
  }

  tags = merge(local.default_tags, var.tags)
}

####################################
# Resource Groups
####################################

module "rg_hub" {
  source   = "./modules/resource-group"
  name     = "rg-${local.name_prefix}-hub"
  location = var.location
  tags     = local.tags
}

module "rg_spoke" {
  source   = "./modules/resource-group"
  name     = "rg-${local.name_prefix}-spoke"
  location = var.location
  tags     = local.tags
}

module "rg_aks" {
  source   = "./modules/resource-group"
  name     = "rg-${local.name_prefix}-aks"
  location = var.location
  tags     = local.tags
}

module "rg_platform" {
  source   = "./modules/resource-group"
  name     = "rg-${local.name_prefix}-platform"
  location = var.location
  tags     = local.tags
}

####################################
# Networking - Hub & Spoke
####################################

module "networking" {
  source = "./modules/networking"

  name_prefix         = local.name_prefix
  location            = var.location
  hub_rg_name         = module.rg_hub.name
  spoke_rg_name       = module.rg_spoke.name
  hub_vnet_cidr       = var.hub_vnet_cidr
  spoke_vnet_cidr     = var.spoke_vnet_cidr
  aks_subnet_cidr     = var.aks_subnet_cidr
  pod_subnet_cidr     = var.pod_subnet_cidr
  pe_subnet_cidr      = var.private_endpoint_subnet_cidr
  appgw_subnet_cidr   = var.appgw_subnet_cidr
  firewall_subnet_cidr = var.firewall_subnet_cidr
  bastion_subnet_cidr  = var.bastion_subnet_cidr
  tags                = local.tags
}

####################################
# Azure Firewall (hub egress)
####################################

module "firewall" {
  source = "./modules/firewall"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.rg_hub.name
  subnet_id           = module.networking.firewall_subnet_id
  log_analytics_id    = module.log_analytics.workspace_id
  tags                = local.tags
}

####################################
# Private DNS Zones
####################################

module "private_dns" {
  source = "./modules/private-dns"

  resource_group_name = module.rg_hub.name
  hub_vnet_id         = module.networking.hub_vnet_id
  spoke_vnet_id       = module.networking.spoke_vnet_id
  location            = var.location
  tags                = local.tags
}

####################################
# Log Analytics & Monitoring
####################################

module "log_analytics" {
  source = "./modules/log-analytics"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.rg_platform.name
  retention_days      = var.log_retention_days
  tags                = local.tags
}

module "monitor" {
  source = "./modules/monitor"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.rg_platform.name
  workspace_id        = module.log_analytics.workspace_id
  email_receivers     = var.alert_email_receivers
  teams_webhook_url   = var.teams_webhook_url
  aks_cluster_id      = module.aks.cluster_id
  tags                = local.tags
}

####################################
# Key Vault
####################################

module "keyvault" {
  source = "./modules/keyvault"

  name_prefix              = local.name_prefix
  location                 = var.location
  resource_group_name      = module.rg_platform.name
  tenant_id                = var.tenant_id
  pe_subnet_id             = module.networking.pe_subnet_id
  private_dns_zone_id      = module.private_dns.kv_zone_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                     = local.tags
}

####################################
# Azure Container Registry
####################################

module "acr" {
  source = "./modules/acr"

  name_prefix              = local.name_prefix
  location                 = var.location
  resource_group_name      = module.rg_platform.name
  pe_subnet_id             = module.networking.pe_subnet_id
  private_dns_zone_id      = module.private_dns.acr_zone_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  geo_replication_locations = var.environment == "prod" ? [var.secondary_location] : []
  tags                     = local.tags
}

####################################
# AKS Cluster
####################################

module "aks" {
  source = "./modules/aks"

  name_prefix             = local.name_prefix
  location                = var.location
  resource_group_name     = module.rg_aks.name
  node_resource_group     = "rg-${local.name_prefix}-aks-nodes"
  kubernetes_version      = var.kubernetes_version
  aks_subnet_id           = module.networking.aks_subnet_id
  pod_subnet_id           = module.networking.pod_subnet_id
  private_cluster_enabled = var.enable_private_cluster
  private_dns_zone_id     = module.private_dns.aks_zone_id
  admin_group_object_ids  = var.admin_group_object_ids
  workspace_id            = module.log_analytics.workspace_id
  acr_id                  = module.acr.acr_id
  keyvault_id             = module.keyvault.keyvault_id
  system_node_pool        = var.system_node_pool
  user_node_pool          = var.user_node_pool
  spot_node_pool          = var.spot_node_pool
  tags                    = local.tags
}

####################################
# Security baseline
####################################

module "security" {
  source = "./modules/security"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.rg_platform.name
  subscription_id     = var.subscription_id
  log_analytics_id    = module.log_analytics.workspace_id
  tags                = local.tags
}

####################################
# Governance - Azure Policy
####################################

module "governance" {
  source = "./modules/governance"

  name_prefix        = local.name_prefix
  subscription_id    = var.subscription_id
  aks_cluster_id     = module.aks.cluster_id
  environment        = var.environment
  tags               = local.tags
}

####################################
# Backup (Velero on AKS + Recovery Vault)
####################################

module "backup" {
  source = "./modules/backup"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.rg_platform.name
  aks_cluster_id      = module.aks.cluster_id
  tags                = local.tags
}

####################################
# Ingress Controller (NGINX) + Cert Manager
####################################

module "ingress" {
  source = "./modules/ingress"

  depends_on = [module.aks]

  cluster_endpoint = module.aks.cluster_id
}

####################################
# ArgoCD GitOps
####################################

module "argocd" {
  source = "./modules/argocd"

  depends_on = [module.aks, module.ingress]

  gitops_repo_url    = var.gitops_repo_url
  gitops_repo_branch = var.gitops_repo_branch
  environment        = var.environment
}
