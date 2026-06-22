subscription_id    = "00000000-0000-0000-0000-000000000000"
tenant_id          = "00000000-0000-0000-0000-000000000000"
environment        = "uat"
location           = "eastus2"
secondary_location = "centralus"
platform_name      = "akspf"

hub_vnet_cidr                = "10.2.0.0/22"
spoke_vnet_cidr              = "10.30.0.0/20"
aks_subnet_cidr              = "10.30.0.0/22"
pod_subnet_cidr              = "10.30.4.0/22"
private_endpoint_subnet_cidr = "10.30.8.0/24"
appgw_subnet_cidr            = "10.30.9.0/24"
firewall_subnet_cidr         = "10.2.0.0/26"
bastion_subnet_cidr          = "10.2.0.64/26"

kubernetes_version     = "1.30.3"
enable_private_cluster = true

system_node_pool = {
  vm_size      = "Standard_D4s_v5"
  min_count    = 3
  max_count    = 5
  os_disk_size = 128
  zones        = ["1", "2", "3"]
}

user_node_pool = {
  vm_size      = "Standard_D8s_v5"
  min_count    = 3
  max_count    = 15
  os_disk_size = 256
  zones        = ["1", "2", "3"]
}

spot_node_pool = {
  enabled         = false
  vm_size         = "Standard_D8s_v5"
  min_count       = 0
  max_count       = 0
  os_disk_size    = 128
  spot_max_price  = -1
  eviction_policy = "Delete"
}

log_retention_days    = 60
alert_email_receivers = ["platform-uat@example.com"]

gitops_repo_url    = "https://github.com/example-org/platform-engineering"
gitops_repo_branch = "main"

tags = {
  Environment = "uat"
  Owner       = "platform-team"
}
