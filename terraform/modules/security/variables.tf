variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subscription_id" { type = string }
variable "log_analytics_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
