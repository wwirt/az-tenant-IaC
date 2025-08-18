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
      # PowerShell script to validate tenant configuration
      Write-Host "Validating tenant configuration..."

      # Load configuration from local.merged_config
      $config = ConvertFrom-Json '${jsonencode(local.merged_config)}'

      # Validate tenant display name
      if (-not $config.tenant.display_name) {
          Write-Error "Tenant display_name is required in configuration"
          exit 1
      }

      # Validate management group hierarchy for circular dependencies
      $mg_dict = @{}
      foreach ($mg in $config.management_groups) {
          $mg_dict[$mg.name] = $mg
      }

      # Check for circular dependencies
      function Has-Cycle {
          param (
              [string]$node_name,
              [System.Collections.ArrayList]$path = $([System.Collections.ArrayList]::new())
          )
          
          if ($path -contains $node_name) {
              Write-Error "Circular dependency detected in management group hierarchy: $($path + $node_name)"
              return $true
          }
          
          if (-not $mg_dict.ContainsKey($node_name)) {
              return $false
          }
          
          $parent_id = $mg_dict[$node_name].parent_id
          if (-not $parent_id) {
              return $false
          }
          
          $path.Add($node_name)
          $cycle = Has-Cycle -node_name $parent_id -path $path
          $path.RemoveAt($path.Count - 1)
          
          return $cycle
      }

      foreach ($mg in $config.management_groups) {
          if (Has-Cycle -node_name $mg.name) {
              exit 1
          }
      }

      # Validate subscription references to management groups
      foreach ($sub in $config.subscriptions) {
          if (-not $mg_dict.ContainsKey($sub.management_group_id)) {
              Write-Error "Subscription $($sub.name) references non-existent management group $($sub.management_group_id)"
              exit 1
          }
      }

      Write-Host "✓ Tenant configuration validation successful"
      exit 0
    EOT
    interpreter = ["pwsh", "-Command"]
  }
}
