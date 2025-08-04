# Data source to get current tenant information
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

# Management Groups
resource "azurerm_management_group" "management_groups" {
  for_each = {
    for mg in local.merged_config.management_groups : mg.name => mg
  }

  name                       = each.value.name
  display_name               = each.value.display_name
  parent_management_group_id = each.value.parent_id

  # Add default diagnostic settings
  dynamic "email_notification" {
    for_each = try(each.value.notifications, false) ? [1] : []
    content {
      custom_emails                  = try(each.value.notifications_emails, [])
      enable_recommendation_alert     = true
      enable_security_alert          = true
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [
      # Ignore changes to tags that might be managed outside of Terraform
      tags
    ]
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
    Name            = each.value.name
    TenantId        = data.azurerm_client_config.current.tenant_id
    SubscriptionId  = lookup(each.value, "subscription_id", "")
    ManagementGroup = each.value.management_group_id
  })

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
    read   = "5m"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [
      # Ignore changes to tags that might be managed outside of Terraform
      tags["LastModifiedBy"],
      tags["CreatedDate"]
    ]
  }
}

# Associate subscriptions with management groups
resource "azurerm_management_group_subscription_association" "subscription_associations" {
  for_each = {
    for sub in local.merged_config.subscriptions : sub.alias => sub
  }

  management_group_id = azurerm_management_group.management_groups[each.value.management_group_id].id
  subscription_id     = azurerm_subscription.subscriptions[each.key].subscription_id

  # Add timeout settings for large-scale operations
  timeouts {
    create = "15m"
    read   = "5m"
    delete = "15m"
  }

  depends_on = [
    azurerm_management_group.management_groups,
    azurerm_subscription.subscriptions
  ]
}

# Policy assignments will be managed in a separate pipeline
# Removed tenant-level Azure Policy assignments section
