variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "workspace_id" { type = string }
variable "aks_cluster_id" { type = string }

variable "email_receivers" {
  type    = list(string)
  default = []
}

variable "teams_webhook_url" {
  type      = string
  default   = ""
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
