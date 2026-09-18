include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config("env.hcl")
}

#remote_state {
#  backend = "local"
#  generate = {
#    path      = "backend.tf"
#    if_exists = "overwrite_terragrunt"
#  }
#  config = {
#    path = "${get_terragrunt_dir()}/terraform.tfstate"
#  }
#}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.6"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "${local.env.locals.subscription_id}"
}

provider "azuread" {}
EOF
}

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = local.env.locals.resource_group_name
    storage_account_name = local.env.locals.storage_account_name
    container_name        = local.env.locals.container_names[0]
    key                    = "01bootstrap/prd/terraform.tfstate"
    use_azuread_auth       = true
    subscription_id        = local.env.locals.subscription_id
  }
}

inputs = local.env.locals
