# Data source to get current tenant information
data "azuread_client_config" "current" {}

# Management Groups
resource "azurerm_management_group" "management_groups" {
  for_each = {
    for mg in local.merged_config.management_groups : mg.name => mg
  }

  name                       = each.value.name
  display_name              = each.value.display_name
  parent_management_group_id = each.value.parent_id

  lifecycle {
    prevent_destroy = true
  }
}

# Subscriptions
resource "azurerm_subscription" "subscriptions" {
  for_each = {
    for sub in local.merged_config.subscriptions : sub.alias => sub
  }

  alias             = each.value.alias
  subscription_name = each.value.name
  workload          = each.value.workload
  billing_scope_id  = each.value.billing_scope_id

  tags = merge(local.common_tags, {
    Name = each.value.name
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Associate subscriptions with management groups
resource "azurerm_management_group_subscription_association" "subscription_associations" {
  for_each = {
    for sub in local.merged_config.subscriptions : sub.alias => sub
  }

  management_group_id = azurerm_management_group.management_groups[each.value.management_group_id].id
  subscription_id     = azurerm_subscription.subscriptions[each.key].subscription_id

  depends_on = [
    azurerm_management_group.management_groups,
    azurerm_subscription.subscriptions
  ]
}
