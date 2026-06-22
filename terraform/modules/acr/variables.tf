variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "pe_subnet_id" { type = string }
variable "private_dns_zone_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "geo_replication_locations" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
