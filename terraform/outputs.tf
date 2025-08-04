output "tenant_id" {
  description = "The ID of the Azure AD tenant"
  value       = data.azuread_client_config.current.tenant_id
}

output "tenant_details" {
  description = "Tenant configuration details"
  value = {
    display_name = local.merged_config.tenant.display_name
    domain_name  = local.merged_config.tenant.domain_name
    tenant_id    = data.azuread_client_config.current.tenant_id
  }
}

output "management_groups" {
  description = "Created management groups with hierarchy information"
  value = {
    for k, mg in azurerm_management_group.management_groups : k => {
      id           = mg.id
      name         = mg.name
      display_name = mg.display_name
      parent_id    = mg.parent_management_group_id
    }
  }
}

output "management_group_hierarchy" {
  description = "Visual representation of management group hierarchy (for documentation)"
  value = {
    root_groups = [
      for k, mg in azurerm_management_group.management_groups : 
        mg.name if mg.parent_management_group_id == null
    ]
    hierarchy = {
      for parent_mg in azurerm_management_group.management_groups :
      parent_mg.name => [
        for child_mg in azurerm_management_group.management_groups :
          child_mg.name if child_mg.parent_management_group_id == parent_mg.id
      ] if length([
        for child_mg in azurerm_management_group.management_groups :
          child_mg.name if child_mg.parent_management_group_id == parent_mg.id
      ]) > 0
    }
  }
}

output "subscriptions" {
  description = "Created subscriptions with detailed information"
  value = {
    for k, sub in azurerm_subscription.subscriptions : k => {
      id              = sub.subscription_id
      name            = sub.subscription_name
      alias           = sub.alias
      workload        = sub.workload
    }
  }
  sensitive = false
}

output "subscription_count" {
  description = "Number of subscriptions managed"
  value       = length(azurerm_subscription.subscriptions)
}

output "subscription_management_group_associations" {
  description = "Subscription to management group associations"
  value = {
    for k, assoc in azurerm_management_group_subscription_association.subscription_associations : k => {
      subscription_id     = assoc.subscription_id
      management_group_id = assoc.management_group_id
    }
  }
}

output "deployment_information" {
  description = "Information about the deployment"
  value = {
    deployment_time = timestamp()
    terraform_version = terraform.version
    environment = var.environment
  }
}
