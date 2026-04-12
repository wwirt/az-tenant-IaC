# Azure Tenant Infrastructure as Code (IaC)
Azure DevOps CI/CD pipeline for Azure tenant infrastructure including management groups and subscriptions using Terraform.

## Overview

This solution provides:
- Azure DevOps CI/CD pipelines for automated validation and deployment of management groups, subscriptions, and diagnostic settings.
- A centralized YAML configuration for Azure tenant management.
- Terraform IaC for management groups, subscriptions, associations, and diagnostic settings.
- Environment scoping via an `environment` field on subscriptions within the single YAML file.

## Project Structure

```
.
├── azure-pipelines-ci.yml          # CI pipeline: YAML validation + terraform validate/plan
├── azure-pipelines-cd.yml          # CD pipeline: template-based dev & prod deployments
├── templates/
│   └── deployment-job-template.yml # Reusable deployment job (validation + init/plan/apply)
├── config/
│   └── tenant.yml                  # Central tenant, management groups, and all subscriptions
├── terraform/
│   ├── main.tf                     # Provider & backend stub
│   ├── variables.tf                # Input variables (config_file, environment, etc.)
│   ├── locals.tf                   # Load & filter YAML (subscriptions filtered by environment)
│   ├── tenant.tf                   # Management groups, subscriptions, associations
│   ├── diagnostics.tf              # Optional diagnostic settings
│   ├── outputs.tf                  # Output definitions
│   └── terraform.tfvars.example    # Example variable values
└── README.md
```

## Configuration Model

A single, centralized YAML file (`config/tenant.yml`) defines the entire tenant structure, removing duplication and the need for multiple files.

- **`tenant.yml`**: Contains the `tenant` object, a `management_groups` array defining the full hierarchy, and a unified `subscriptions` array. Each subscription includes an `environment` key (`dev`, `prod`, etc.) used for filtering.

Terraform loads this file via the `config_file` variable. In `locals.tf`, subscriptions are filtered based on the target environment:
```hcl
filtered_subscriptions = [for sub in local.config.subscriptions : sub if sub.environment == var.environment]
```
This ensures each deployment affects only its intended environment scope.

## Pipelines

### CI (`azure-pipelines-ci.yml`)
Steps:
1. YAML validation (syntax check of `tenant.yml`)
2. Terraform init/validate
3. Terraform plan (uses `tenant.yml` and sets `environment=prod` for consistency)

### CD (`azure-pipelines-cd.yml`)
Stages:
- `Deploy_Dev`
- `Deploy_Prod`

Both stages call the template `templates/deployment-job-template.yml` with parameters:
- `terraformStateKey` (separate state per environment)
- `environmentShort` (passed to Terraform as `-var="environment=..."`)

Template actions:
1. Validate referenced management groups for environment-scoped subscriptions.
2. Terraform install, init, plan, and apply (using the central config filtered by environment).

## Local Usage

From the `terraform/` directory:
```powershell
# Initialize Terraform
terraform init

# Plan for the 'dev' environment
terraform plan -var="environment=dev"

# Apply for the 'dev' environment
terraform apply -var="environment=dev"

# Plan for the 'prod' environment
terraform plan -var="environment=prod"
```
The `config_file` variable defaults to `../config/tenant.yml`, so it doesn't need to be specified.

## Adding a New Environment

1. Add subscriptions to `config/tenant.yml` with a new `environment` value (e.g., `staging`).
2. Add any required management groups to the `management_groups` list in the same file.
3. Create a new stage in `azure-pipelines-cd.yml` reusing the template with a distinct `terraformStateKey`.
4. Run CI, then merge the branch corresponding to the new environment trigger convention.

## YAML Structure Example

```yaml
# config/tenant.yml
tenant:
  display_name: "Contoso Tenant"
  domain_name: "contoso.onmicrosoft.com"

management_groups:
  - name: "mg-root"
    display_name: "Root Management Group"
    parent_id: null # Root groups use a null parent_id
  - name: "mg-platform"
    display_name: "Platform"
    parent_id: "mg-root"

subscriptions:
  - name: "Production Workloads"
    alias: "prod-workloads"
    management_group_id: "mg-workloads-prod"
    workload: "Production"
    environment: "prod"
  - name: "Development Workloads"
    alias: "dev-workloads"
    management_group_id: "mg-workloads-dev"
    workload: "Development"
    environment: "dev"
```

## Troubleshooting

- **Missing management group**: Ensure the `management_group_id` referenced in a subscription exists in the `management_groups` list in `tenant.yml`.
- **Empty plan**: Verify the `environment` variable value matches the `environment` key in the desired subscription entries.
- **Backend lock**: Check the Azure Storage `tfstate` container for locks.

## Best Practices

- Keep all configuration in the single `tenant.yml` file.
- Use the `environment` key within subscriptions to control deployment scope.
- Use separate state keys per environment.
- Review plan output in CI before deploying.

## Deprecated

The following are no longer used and have been removed:
- All `.json` configuration files (`tenant-config.json`, `management-groups.json`, etc.).
- Per-environment configuration files.

Centralization into a single YAML file reduces drift and improves auditability.
