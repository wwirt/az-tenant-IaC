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

# CIS Azure Benchmark Policy Assignments
resource "azurerm_management_group_policy_assignment" "cis_azure_security_benchmark" {
  name                 = "cis-azure-security-benchmark"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  management_group_id  = azurerm_management_group.management_groups["mg-root"].id
  display_name         = "CIS Microsoft Azure Foundations Benchmark v1.4.0"
  description          = "CIS Azure Security Benchmark policy initiative"

  parameters = jsonencode({
    "effect-b954148f-4c11-4c38-8221-be76711e194a-MicrosoftSql-servers-firewallRules-delete" = {
      value = "AuditIfNotExists"
    }
  })

  identity {
    type = "SystemAssigned"
  }

  location = var.location

  depends_on = [azurerm_management_group.management_groups]
}

# Azure Security Center Standard Tier
resource "azurerm_security_center_subscription_pricing" "security_center" {
  for_each = {
    for sub in local.merged_config.subscriptions : sub.alias => sub
  }

  tier          = "Standard"
  resource_type = "VirtualMachines"
  subscription_id = azurerm_subscription.subscriptions[each.key].subscription_id

  depends_on = [azurerm_subscription.subscriptions]
}

# Location Restriction Policy
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  count                = try(local.merged_config.security_policies.azure_policies.allowed_locations, null) != null ? 1 : 0
  name                 = "allowed-locations"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  management_group_id  = azurerm_management_group.management_groups["mg-root"].id
  display_name         = "Allowed locations"
  description          = "Restrict resource deployment to approved Azure regions"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = try(local.merged_config.security_policies.azure_policies.allowed_locations, ["West Europe", "North Europe"])
    }
  })

  depends_on = [azurerm_management_group.management_groups]
}

# Deny Public Storage Accounts
resource "azurerm_management_group_policy_assignment" "deny_public_storage" {
  count                = try(local.merged_config.security_policies.azure_policies.deny_public_storage_accounts, false) ? 1 : 0
  name                 = "deny-public-storage"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/34c877ad-507e-4c82-993e-3452a6e0ad3c"
  management_group_id  = azurerm_management_group.management_groups["mg-root"].id
  display_name         = "Storage accounts should restrict network access"
  description          = "Deny storage accounts with public network access"

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })

  depends_on = [azurerm_management_group.management_groups]
}

# Require HTTPS for Storage Accounts
resource "azurerm_management_group_policy_assignment" "require_https_storage" {
  count                = try(local.merged_config.security_policies.azure_policies.require_https_traffic_only, false) ? 1 : 0
  name                 = "require-https-storage"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
  management_group_id  = azurerm_management_group.management_groups["mg-root"].id
  display_name         = "Secure transfer to storage accounts should be enabled"
  description          = "Require HTTPS traffic only to storage accounts"

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })

  depends_on = [azurerm_management_group.management_groups]
}

# Deny RDP from Internet
resource "azurerm_management_group_policy_assignment" "deny_rdp_internet" {
  count                = try(local.merged_config.security_policies.azure_policies.deny_rdp_from_internet, false) ? 1 : 0
  name                 = "deny-rdp-internet"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e372f825-a257-4fb8-9175-797a8a8627d6"
  management_group_id  = azurerm_management_group.management_groups["mg-root"].id
  display_name         = "RDP access from the Internet should be blocked"
  description          = "Deny RDP access from internet to virtual machines"

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })

  depends_on = [azurerm_management_group.management_groups]
}

# Deny SSH from Internet
resource "azurerm_management_group_policy_assignment" "deny_ssh_internet" {
  count                = try(local.merged_config.security_policies.azure_policies.deny_ssh_from_internet, false) ? 1 : 0
  name                 = "deny-ssh-internet"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2c89a2e5-7285-40fe-aca4-6a1fe31e94c2"
  management_group_id  = azurerm_management_group.management_groups["mg-root"].id
  display_name         = "SSH access from the Internet should be blocked"
  description          = "Deny SSH access from internet to virtual machines"

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })

  depends_on = [azurerm_management_group.management_groups]
}
