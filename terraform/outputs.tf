output "tenant_id" {
  description = "The ID of the Azure AD tenant"
  value       = data.azuread_client_config.current.tenant_id
}

output "management_groups" {
  description = "Created management groups"
  value = {
    for k, mg in azurerm_management_group.management_groups : k => {
      id           = mg.id
      name         = mg.name
      display_name = mg.display_name
    }
  }
}

output "subscriptions" {
  description = "Created subscriptions"
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

output "subscription_management_group_associations" {
  description = "Subscription to management group associations"
  value = {
    for k, assoc in azurerm_management_group_subscription_association.subscription_associations : k => {
      subscription_id     = assoc.subscription_id
      management_group_id = assoc.management_group_id
    }
  }
}
