variable "gitops_repo_url" { type = string }
variable "gitops_repo_branch" {
  type    = string
  default = "main"
}
variable "environment" { type = string }
