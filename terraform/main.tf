terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    # Backend configuration will be provided via Azure DevOps pipeline
    # Expected variables: resource_group_name, storage_account_name, container_name, key
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    
    management_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  
  # Skip provider registration for tenant-level operations
  skip_provider_registration = true
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  # Configuration will be inherited from service principal
  # Ensure service principal has appropriate tenant-level permissions
}

# Data sources for current Azure context
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

# Output current tenant information for validation
output "tenant_info" {
  description = "Current tenant information"
  value = {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
  }
  sensitive = false
}

# Output merged configuration for debugging
output "merged_config_summary" {
  description = "Summary of merged configuration"
  value = {
    tenant_display_name = local.merged_config.tenant.display_name
    tenant_domain_name = local.merged_config.tenant.domain_name
    management_groups_count = length(local.merged_config.management_groups)
    subscriptions_count = length(local.merged_config.subscriptions)
    security_policies_enabled = length(keys(local.merged_config.security_policies)) > 0
  }
}
