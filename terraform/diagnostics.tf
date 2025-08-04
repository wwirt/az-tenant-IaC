# Diagnostic settings for subscriptions and resources

# Define Log Analytics Workspace for diagnostic settings
resource "azurerm_log_analytics_workspace" "diagnostics" {
  count               = var.enable_diagnostics ? 1 : 0
  name                = "log-${var.environment}-central-diagnostics"
  location            = var.location
  resource_group_name = "${var.environment}-monitoring-rg"
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = local.common_tags
}

# Create diagnostic setting for each subscription
resource "azurerm_monitor_diagnostic_setting" "subscription_diagnostics" {
  for_each = var.enable_diagnostics ? {
    for sub in local.merged_config.subscriptions : sub.alias => sub
  } : {}

  name                       = "diag-${each.value.alias}"
  target_resource_id         = "/subscriptions/${azurerm_subscription.subscriptions[each.key].subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.diagnostics[0].id

  log {
    category = "Administrative"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "Security"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "ServiceHealth"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "Alert"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "Recommendation"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "Policy"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "Autoscale"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "ResourceHealth"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }
  
  depends_on = [
    azurerm_subscription.subscriptions,
    azurerm_log_analytics_workspace.diagnostics
  ]
}
