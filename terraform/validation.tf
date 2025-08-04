# Error handling and validation
terraform {
  required_version = ">= 1.5.0"
  
  # This ensures resources are successfully created before the plan is considered applied
  experiments = [module_variable_optional_attrs]
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
      configuration_aliases = [ azurerm.connectivity ]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# Validate tenant configuration before attempting to apply
resource "null_resource" "validate_tenant_config" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      # Ensure required values exist in tenant config
      if [ -z "${local.merged_config.tenant.display_name}" ]; then
        echo "ERROR: Tenant display_name is required in configuration"
        exit 1
      fi
      
      # Validate management group hierarchy for circular dependencies
      python -c '
import json
import sys

config = json.loads("""${jsonencode(local.merged_config)}""")
mg_dict = {mg["name"]: mg for mg in config["management_groups"]}

# Check for circular dependencies
visited = set()
temp_path = set()

def has_cycle(node_name, path=None):
    if path is None:
        path = []
    
    if node_name in temp_path:
        print(f"ERROR: Circular dependency detected in management group hierarchy: {path + [node_name]}")
        return True
    
    if node_name in visited:
        return False
    
    if node_name not in mg_dict:
        return False
    
    parent_id = mg_dict[node_name].get("parent_id")
    if not parent_id:
        return False
    
    temp_path.add(node_name)
    path.append(node_name)
    has_cycle_result = has_cycle(parent_id, path)
    temp_path.remove(node_name)
    
    if not has_cycle_result:
        visited.add(node_name)
    
    return has_cycle_result

for mg in config["management_groups"]:
    if has_cycle(mg["name"]):
        sys.exit(1)

# Validate subscription references to management groups
for sub in config["subscriptions"]:
    if sub["management_group_id"] not in mg_dict:
        print(f"ERROR: Subscription {sub['name']} references non-existent management group {sub['management_group_id']}")
        sys.exit(1)
'
      
      echo "✓ Tenant configuration validation successful"
    EOT
    
    interpreter = ["bash", "-c"]
  }
}
