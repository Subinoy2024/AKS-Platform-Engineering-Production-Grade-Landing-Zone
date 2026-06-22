variable "name_prefix" { type = string }
variable "subscription_id" { type = string }
variable "aks_cluster_id" { type = string }
variable "environment" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
