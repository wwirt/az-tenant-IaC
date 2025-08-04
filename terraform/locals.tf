# Load tenant configuration from JSON file
locals {
  # Load the JSON configuration file
  config_file_path = var.config_file_path != "" ? var.config_file_path : "../config/tenant-config.json"
  tenant_config_raw = file(local.config_file_path)
  tenant_config = jsondecode(local.tenant_config_raw)
  
  # Merge with additional variables
  merged_config = {
    tenant = local.tenant_config.tenant
    management_groups = local.tenant_config.management_groups
    subscriptions = local.tenant_config.subscriptions
  }
  
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Environment = var.environment
    LastModified = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  })
}
