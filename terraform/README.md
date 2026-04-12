# Azure Tenant Template - Terraform Module

This Terraform module provides a stable and reusable template for creating and managing Azure tenants, management groups, and subscriptions using a centralized YAML configuration.

## Features

- **Centralized Configuration**: Manage your entire tenant structure from a single YAML file.
- **Environment Filtering**: Deploy specific environments (e.g., dev, prod) from the same configuration file.
- **Management Group Hierarchy**: Define hierarchical organization structures with proper inheritance.
- **Subscription Management**: Create and organize subscriptions under management groups.
- **Validation**: Built-in validation to prevent circular dependencies and configuration errors.
- **Error Handling**: Graceful handling of missing files and optional parameters.

## Usage

1. **Clone the Repository**
```bash
git clone https://github.com/yourorg/az-tenant-IaC.git
cd az-tenant-IaC
```

2. **Configure Tenant Settings**
- Modify `config/tenant.yml` to define your tenant, management groups, and subscriptions.

3. **Initialize and Apply**
```bash
cd terraform
terraform init
terraform plan -var="environment=prod" -out=tfplan
terraform apply tfplan
```

## Configuration Structure

The entire configuration is managed in `config/tenant.yml`.

### Basic Structure
```yaml
tenant:
  display_name: "Your Tenant Name"
  domain_name: "yourdomain.onmicrosoft.com"

management_groups:
  - name: "mg-root"
    display_name: "Root Management Group"
    parent_id: null
  - name: "mg-platform"
    display_name: "Platform"
    parent_id: "mg-root"

subscriptions:
  - name: "Platform Services"
    alias: "platform-services"
    management_group_id: "mg-platform"
    workload: "Production"
    environment: "prod"
  - name: "Application Workloads"
    alias: "app-workloads"
    management_group_id: "mg-landing-zones"
    workload: "Development"
    environment: "dev"
```

## CI/CD Pipeline

This project includes Azure DevOps CI/CD pipelines for automated deployment:

- **azure-pipelines-ci.yml**: Validation and planning
- **azure-pipelines-cd.yml**: Deployment to environments

## Best Practices

1. **Least Privilege**: Use separate service connections for state management and tenant management.
2. **Configuration as Code**: Store the `tenant.yml` file in version control.
3. **Validation First**: The CI pipeline validates the configuration before deployment.
4. **State Protection**: Use remote state with proper access controls.
5. **Environment Separation**: Use the `environment` variable to deploy specific environments from the single configuration file.

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| config_file | Path to the YAML configuration file | "../config/tenant.yml" |
| tenant_display_name | Default tenant name if not in config | "Default Tenant" |
| tenant_domain_name | Default domain if not in config | "defaulttenant.onmicrosoft.com" |
| environment | Deployment environment (e.g., dev, prod) | "dev" |
| location | Azure region for resources | "East US" |
| deployment_version | Version tag for resources | "1.0.0" |
| enable_diagnostics | Enable diagnostic settings | true |

## Troubleshooting

- **Circular Dependencies**: Check for circular references in the `management_groups` hierarchy in `tenant.yml`.
- **Missing Management Groups**: Ensure all `management_group_id` values in the `subscriptions` list correspond to a management group defined in the `management_groups` list.
- **Permission Errors**: Verify service principal permissions.
- **State Locks**: Clear any existing state locks if a deployment fails.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Ensure CI passes all validation checks
