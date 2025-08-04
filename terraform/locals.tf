# Load tenant configuration from JSON file
locals {
  # Load the JSON configuration file with defaults and error handling
  config_file_path = var.config_file_path != "" ? var.config_file_path : "../config/tenant-config.json"
  tenant_config_raw = fileexists(local.config_file_path) ? file(local.config_file_path) : "{}"
  tenant_config = jsondecode(local.tenant_config_raw)
  
  # Set default values to prevent errors
  default_tenant = {
    tenant = {
      display_name = var.tenant_display_name
      domain_name = var.tenant_domain_name
    }
    management_groups = []
    subscriptions = []
  }
  
  # Merge with additional variables and defaults
  merged_config = {
    tenant = lookup(local.tenant_config, "tenant", local.default_tenant.tenant)
    management_groups = lookup(local.tenant_config, "management_groups", local.default_tenant.management_groups)
    subscriptions = lookup(local.tenant_config, "subscriptions", local.default_tenant.subscriptions)
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
