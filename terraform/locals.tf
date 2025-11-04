# Load tenant configuration from JSON file
locals {
  # Load tenant configuration from the single source of truth
  tenant_config_file = file(var.tenant_config_file)
  tenant_config = jsondecode(tenant_config_file)

  # Filter subscriptions based on the current environment
  filtered_subscriptions = [
    for sub in local.tenant_config.subscriptions : sub
    if sub.environment == var.environment
  ]

  # Load the shared management groups structure
  management_groups_file = file(var.management_groups_file)
  management_groups_config = jsondecode(management_groups_file)

  # Merge with additional variables and defaults
  merged_config = {
    tenant            = local.tenant_config.tenant
    management_groups = local.management_groups_config.management_groups
    subscriptions     = local.filtered_subscriptions
  }

  # Common tags for all resources
  common_tags = merge(var.tags, {
    Environment = var.environment
    LastModified = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    TerraformManaged = "true"
    TerraformWorkspace = terraform.workspace
    DeploymentVersion = var.deployment_version
  })
}
