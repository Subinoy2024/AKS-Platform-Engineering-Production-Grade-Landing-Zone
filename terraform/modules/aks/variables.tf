variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "node_resource_group" { type = string }
variable "kubernetes_version" { type = string }
variable "aks_subnet_id" { type = string }
variable "pod_subnet_id" { type = string }
variable "private_cluster_enabled" { type = bool }
variable "private_dns_zone_id" {
  type    = string
  default = null
}
variable "admin_group_object_ids" {
  type    = list(string)
  default = []
}
variable "workspace_id" { type = string }
variable "acr_id" { type = string }
variable "keyvault_id" { type = string }

variable "system_node_pool" {
  type = object({
    vm_size      = string
    min_count    = number
    max_count    = number
    os_disk_size = number
    zones        = list(string)
  })
}

variable "user_node_pool" {
  type = object({
    vm_size      = string
    min_count    = number
    max_count    = number
    os_disk_size = number
    zones        = list(string)
  })
}

variable "spot_node_pool" {
  type = object({
    enabled         = bool
    vm_size         = string
    min_count       = number
    max_count       = number
    os_disk_size    = number
    spot_max_price  = number
    eviction_policy = string
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
