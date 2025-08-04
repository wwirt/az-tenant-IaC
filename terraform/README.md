# Azure Tenant Template - Terraform Module

This Terraform module provides a stable and reusable template for creating and managing Azure tenants, management groups, and subscriptions. It's been enhanced to handle multiple tenant environments with robust error handling and standardized patterns.

## Features

- **Multi-Tenant Management**: Configure and deploy multiple Azure tenant configurations
- **Management Group Hierarchy**: Define hierarchical organization structures with proper inheritance
- **Subscription Management**: Create and organize subscriptions under management groups
- **Policy Management**: Apply Azure policies at the tenant and management group level
- **Validation**: Built-in validation to prevent circular dependencies and configuration errors
- **Error Handling**: Graceful handling of missing files and optional parameters

## Usage

1. **Clone the Repository**
```bash
git clone https://github.com/yourorg/az-tenant-IaC.git
cd az-tenant-IaC
```

2. **Configure Tenant Settings**
- Use `config/tenant-template.json` as a starting point
- Create environment-specific configs like `dev-config.json` or `prod-config.json`

3. **Initialize and Apply**
```bash
cd terraform
terraform init
terraform plan -var-file="../config/your-tenant-config.json" -out=tfplan
terraform apply tfplan
```

## Configuration Structure

### Basic Structure
```json
{
  "tenant": {
    "display_name": "Your Tenant Name",
    "domain_name": "yourdomain.onmicrosoft.com"
  },
  "management_groups": [
    {
      "name": "mg-root",
      "display_name": "Root Management Group",
      "parent_id": null
    },
    {
      "name": "mg-platform",
      "display_name": "Platform",
      "parent_id": "mg-root"
    }
  ],
  "subscriptions": [
    {
      "name": "Platform Services",
      "alias": "platform-services",
      "management_group_id": "mg-platform",
      "workload": "Production"
    }
  ],
  "tenant_policies": {
    "policy-name": {
      "management_group_id": "mg-root",
      "policy_definition_id": "/providers/Microsoft.Authorization/policyDefinitions/POLICY_ID",
      "display_name": "Policy Display Name",
      "parameters": {}
    }
  }
}
```

## Templates and Examples

The repository includes several template configurations:

- **tenant-template.json**: Reference template with comprehensive structure
- **dev-config.json**: Example development environment configuration
- **prod-config.json**: Example production environment configuration

## CI/CD Pipeline

This project includes Azure DevOps CI/CD pipelines for automated deployment:

- **azure-pipelines-ci.yml**: Validation and planning
- **azure-pipelines-cd.yml**: Deployment to environments

## Best Practices

1. **Least Privilege**: Use separate service connections for state management and tenant management
2. **Configuration as Code**: Store all tenant configurations as versioned JSON files
3. **Validation First**: CI pipeline validates configuration before deployment
4. **State Protection**: Use remote state with proper access controls
5. **Environment Separation**: Maintain separate configurations for each environment

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| config_file_path | Path to JSON configuration file | "" |
| tenant_display_name | Default tenant name if not in config | "Default Tenant" |
| tenant_domain_name | Default domain if not in config | "defaulttenant.onmicrosoft.com" |
| environment | Deployment environment | "dev" |
| location | Azure region for resources | "East US" |
| deployment_version | Version tag for resources | "1.0.0" |
| enable_diagnostics | Enable diagnostic settings | true |

## Extended Configuration

### Adding Custom Policies

The template supports custom policy definitions by adding them to the `tenant_policies` section:

```json
"tenant_policies": {
  "custom-policy": {
    "management_group_id": "mg-root",
    "policy_definition_id": "/providers/Microsoft.Authorization/policyDefinitions/POLICY_ID",
    "display_name": "Custom Policy",
    "parameters": {
      "paramName": {
        "value": "paramValue"
      }
    }
  }
}
```

### Management Group Notifications

Enable management group notifications with:

```json
"management_groups": [
  {
    "name": "mg-example",
    "display_name": "Example Group",
    "parent_id": "mg-root",
    "notifications": true,
    "notifications_emails": ["admin@example.com"]
  }
]
```

## Troubleshooting

- **Circular Dependencies**: Check for circular references in management group hierarchy
- **Missing Management Groups**: Ensure all referenced management group IDs exist
- **Permission Errors**: Verify service principal permissions
- **State Locks**: Clear any existing state locks if deployment fails

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Ensure CI passes all validation checks
