# Load tenant configuration from YAML file
locals {
  # Load tenant configuration from the centralized YAML config
  config_file = file(var.config_file)
  config = yamldecode(config_file)

  # Filter subscriptions based on the current environment
  filtered_subscriptions = [
    for sub in local.config.subscriptions : sub
    if sub.environment == var.environment
  ]

  # Merge with additional variables and defaults
  merged_config = {
    tenant            = local.config.tenant
    management_groups = local.config.management_groups
    subscriptions     = local.filtered_subscriptions
  }

  # Common tags for all resources
  common_tags = merge(var.tags, {
    TerraformManaged = "true"
    TerraformWorkspace = terraform.workspace
  })
}
