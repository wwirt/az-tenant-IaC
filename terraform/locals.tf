# Load tenant configuration from JSON file
locals {
  # Load the tenant configuration (prioritize explicit path, then environment-specific, then fallback)
  tenant_config_path = var.tenant_config_file != "" ? var.tenant_config_file : 
                      fileexists("../config/tenant-config.json") ? "../config/tenant-config.json" :
                      fileexists("../config/${var.environment}-config.json") ? "../config/${var.environment}-config.json" : ""
  
  tenant_config_raw = local.tenant_config_path != "" && fileexists(local.tenant_config_path) ? 
                     file(local.tenant_config_path) : "{}"
  tenant_config = jsondecode(local.tenant_config_raw)
  
  # Load the shared management groups structure
  mg_base_path = var.management_groups_file != "" ? var.management_groups_file : "../config/management-groups.json"
  mg_env_path = fileexists("../config/management-groups-${var.environment}.json") ? "../config/management-groups-${var.environment}.json" : ""
  mg_base_raw = fileexists(local.mg_base_path) ? file(local.mg_base_path) : "{}"
  mg_env_raw = local.mg_env_path != "" && fileexists(local.mg_env_path) ? file(local.mg_env_path) : "{}"
  
  # Parse the management group configurations
  mg_base_config = jsondecode(local.mg_base_raw)
  mg_env_config = local.mg_env_path != "" ? jsondecode(local.mg_env_raw) : { management_groups = [] }
  
  # Combine the base and environment-specific management groups
  combined_management_groups = concat(
    try(local.mg_base_config.management_groups, []),
    try(local.mg_env_config.management_groups, [])
  )
  
  # Set default values to prevent errors
  default_tenant = {
    tenant = {
      display_name = var.tenant_display_name
      domain_name = var.tenant_domain_name
    }
    subscriptions = []
    security_policies = {}
  }
  
  # Merge with additional variables and defaults
  merged_config = {
    tenant = lookup(local.tenant_config, "tenant", local.default_tenant.tenant)
    management_groups = local.combined_management_groups
    subscriptions = lookup(local.tenant_config, "subscriptions", local.default_tenant.subscriptions)
    security_policies = lookup(local.tenant_config, "security_policies", local.default_tenant.security_policies)
  }
  
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Environment = var.environment
    LastModified = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    TerraformManaged = "true"
    TerraformWorkspace = terraform.workspace
    DeploymentVersion = var.deployment_version
    TenantId = data.azurerm_client_config.current.tenant_id
  })
}
