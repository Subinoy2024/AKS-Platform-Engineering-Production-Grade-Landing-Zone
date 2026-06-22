####################################
# Core
####################################

variable "subscription_id" {
  description = "Azure Subscription ID where the platform is deployed."
  type        = string
}

variable "tenant_id" {
  description = "Azure Entra ID tenant ID."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, qa, uat, prod)."
  type        = string
  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "environment must be one of dev, qa, uat, prod."
  }
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "eastus2"
}

variable "secondary_location" {
  description = "Secondary Azure region for DR."
  type        = string
  default     = "centralus"
}

variable "platform_name" {
  description = "Short platform name used in naming standards."
  type        = string
  default     = "akspf"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

####################################
# Networking
####################################

variable "hub_vnet_cidr" {
  description = "CIDR for hub VNet."
  type        = string
  default     = "10.0.0.0/22"
}

variable "spoke_vnet_cidr" {
  description = "CIDR for spoke VNet."
  type        = string
  default     = "10.10.0.0/20"
}

variable "aks_subnet_cidr" {
  description = "CIDR for AKS node subnet."
  type        = string
  default     = "10.10.0.0/22"
}

variable "pod_subnet_cidr" {
  description = "CIDR for AKS pod subnet."
  type        = string
  default     = "10.10.4.0/22"
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR for private endpoint subnet."
  type        = string
  default     = "10.10.8.0/24"
}

variable "appgw_subnet_cidr" {
  description = "CIDR for Application Gateway subnet."
  type        = string
  default     = "10.10.9.0/24"
}

variable "firewall_subnet_cidr" {
  description = "CIDR for Azure Firewall subnet."
  type        = string
  default     = "10.0.0.0/26"
}

variable "bastion_subnet_cidr" {
  description = "CIDR for Azure Bastion subnet."
  type        = string
  default     = "10.0.0.64/26"
}

####################################
# AKS
####################################

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.30.3"
}

variable "system_node_pool" {
  description = "System node pool configuration."
  type = object({
    vm_size      = string
    min_count    = number
    max_count    = number
    os_disk_size = number
    zones        = list(string)
  })
  default = {
    vm_size      = "Standard_D4s_v5"
    min_count    = 3
    max_count    = 5
    os_disk_size = 128
    zones        = ["1", "2", "3"]
  }
}

variable "user_node_pool" {
  description = "User node pool configuration."
  type = object({
    vm_size      = string
    min_count    = number
    max_count    = number
    os_disk_size = number
    zones        = list(string)
  })
  default = {
    vm_size      = "Standard_D8s_v5"
    min_count    = 3
    max_count    = 20
    os_disk_size = 256
    zones        = ["1", "2", "3"]
  }
}

variable "spot_node_pool" {
  description = "Spot node pool configuration."
  type = object({
    enabled         = bool
    vm_size         = string
    min_count       = number
    max_count       = number
    os_disk_size    = number
    spot_max_price  = number
    eviction_policy = string
  })
  default = {
    enabled         = true
    vm_size         = "Standard_D8s_v5"
    min_count       = 0
    max_count       = 10
    os_disk_size    = 128
    spot_max_price  = -1
    eviction_policy = "Delete"
  }
}

variable "enable_private_cluster" {
  description = "Deploy AKS as a private cluster."
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster-admin."
  type        = list(string)
  default     = []
}

####################################
# Observability
####################################

variable "log_retention_days" {
  description = "Days to retain log analytics data."
  type        = number
  default     = 30
}

variable "alert_email_receivers" {
  description = "Email addresses for Azure Monitor alerts."
  type        = list(string)
  default     = []
}

variable "teams_webhook_url" {
  description = "Microsoft Teams webhook for alert notifications."
  type        = string
  default     = ""
  sensitive   = true
}

####################################
# GitOps
####################################

variable "gitops_repo_url" {
  description = "Git repository URL for ArgoCD root application."
  type        = string
  default     = "https://github.com/example-org/platform-engineering"
}

variable "gitops_repo_branch" {
  description = "Branch used by ArgoCD."
  type        = string
  default     = "main"
}
