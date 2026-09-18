locals {
  subscription_id      = "ad3acf0d-9fab-4c97-86f1-f7e7a8ef8b4a"
  resource_group_name  = "rg-eus-prd-alpha-ai-tfstate-001"
  location             = "eastus"

  storage_account_name = "01saeusprdalaitfstate"
  replication_type     = "ZRS"
  container_names      = ["azure-databricks-infrastructure"]

  group_display_name   = "entra-sg-prd-devops-engineers"
  group_description    = "PRD DevOps engineers access group. Do not delete — required for RBAC and platform operations."

  group_owner_upns     = ["mohancloud02@thefossgeek.com"]
  group_member_upns    = ["mohancloud01_gmail.com#EXT#@mohancloud01gmail.onmicrosoft.com", "mohancloud02@thefossgeek.com"]

  tags = {
    owner       = "DevOps"
    department  = "Data"
    terraform   = "True"
    repository  = "azure-databricks-infrastructure"
    environment = "prd"
    project     = "alpha-ai"
    costcenter  = "000000"
  }

  # Day 1: leave as-is. Day 2: set enable_private_endpoint = true and fill in
  # private_endpoint_subnet_id / private_dns_zone_id below, then apply again.
  enable_private_endpoint    = false
  private_endpoint_subnet_id = null
  private_dns_zone_id        = null

  # Day 1: leave as-is. Day 2: set enable_diagnostics = true and fill in
  # log_analytics_workspace_id below, then apply again.
  enable_diagnostics         = false
  log_analytics_workspace_id = null
}
