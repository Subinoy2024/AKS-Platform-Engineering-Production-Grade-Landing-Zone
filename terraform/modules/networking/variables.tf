variable "name_prefix" { type = string }
variable "location" { type = string }
variable "hub_rg_name" { type = string }
variable "spoke_rg_name" { type = string }
variable "hub_vnet_cidr" { type = string }
variable "spoke_vnet_cidr" { type = string }
variable "aks_subnet_cidr" { type = string }
variable "pod_subnet_cidr" { type = string }
variable "pe_subnet_cidr" { type = string }
variable "appgw_subnet_cidr" { type = string }
variable "firewall_subnet_cidr" { type = string }
variable "bastion_subnet_cidr" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}
