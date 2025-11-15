# Azure Tenant Infrastructure as Code (IaC)
Azure DevOps CI/CD pipeline for Azure tenant infrastructure including management groups and subscriptions using Terraform
## Overview

This solution provides:
- Azure DevOps CI/CD pipelines for automated validation and deployment of management groups, subscriptions, and diagnostic settings
- Centralized JSON configuration for Azure tenant management
- Terraform IaC for management groups, subscriptions, associations, diagnostic settings
- Environment scoping via an `environment` field on subscriptions

## Project Structure

```
.
├── azure-pipelines-ci.yml          # CI pipeline: JSON validation + terraform validate/plan (prod plan by default)
├── azure-pipelines-cd.yml          # CD pipeline: template-based dev & prod deployments
├── templates/
│   └── deployment-job-template.yml # Reusable deployment job (validation + init/plan/apply)
├── config/
│   ├── tenant-config.json          # Central tenant + all subscriptions (with environment property)
│   ├── management-groups.json      # Full management group hierarchy
│   └── tenant-template.json        # Example starter template for new tenants
├── terraform/
│   ├── main.tf                     # Provider & backend stub
│   ├── variables.tf                # Input variables (tenant_config_file, management_groups_file, environment, etc.)
│   ├── locals.tf                   # Load & filter JSON (subscriptions filtered by environment)
│   ├── tenant.tf                   # Management groups, subscriptions, associations
│   ├── diagnostics.tf              # Optional diagnostic settings
│   ├── outputs.tf                  # Output definitions
│   └── terraform.tfvars.example    # Example variable values
└── README.md
```

## Configuration Model

Centralized configuration removes duplication:
- `tenant-config.json`: Contains `tenant` object and a unified `subscriptions` array. Each subscription includes an `environment` key (`dev`, `prod`, etc.) used for filtering.
- `management-groups.json`: Contains a `management_groups` array defining the hierarchy (each has `name`, `display_name`, `parent_id`).
- No separate `dev-config.json` or `prod-config.json` files.

Terraform loads both files via variables: `tenant_config_file` and `management_groups_file`. In `locals.tf`, subscriptions are filtered:
```
filtered_subscriptions = [for sub in local.tenant_config.subscriptions : sub if sub.environment == var.environment]
```
This ensures each deployment affects only its environment scope.

## Pipelines

### CI (`azure-pipelines-ci.yml`)
Steps:
1. JSON validation (syntax check of all config *.json files)
2. Terraform init/validate
3. Terraform plan (uses `tenant-config.json` + `management-groups.json` and sets `environment=prod` for consistency)

### CD (`azure-pipelines-cd.yml`)
Stages:
- `Deploy_Dev`
- `Deploy_Prod`

Both stages call the template: `templates/deployment-job-template.yml` with parameters:
- `terraformStateKey` (separate state per environment)
- `environmentShort` (passed to Terraform `-var="environment=..."`)

Template actions:
1. Validate referenced management groups for environment-scoped subscriptions
2. Terraform install
3. Terraform init (distinct backend key per env)
4. Terraform plan (central config + environment filter)
5. Terraform apply

## Local Usage

From the `terraform/` directory:
```pwsh
terraform init
terraform plan -var="environment=dev" -var="tenant_config_file=../config/tenant-config.json" -var="management_groups_file=../config/management-groups.json"
terraform apply -var="environment=dev" -var="tenant_config_file=../config/tenant-config.json" -var="management_groups_file=../config/management-groups.json"

# Production example
terraform plan -var="environment=prod" -var="tenant_config_file=../config/tenant-config.json" -var="management_groups_file=../config/management-groups.json"
```

You can optionally supply `-var="deployment_version=1.1.0"` or override tags via `-var='tags={ Project = "Azure-Tenant-IaC" Environment = "prod" }'`.

## Adding a New Environment

1. Add subscriptions to `tenant-config.json` with a new `environment` value (e.g., `staging`).
2. Add any required management groups to `management-groups.json` referencing parents.
3. Create a new stage in `azure-pipelines-cd.yml` reusing the template with a distinct `terraformStateKey`.
4. Run CI then merge branch corresponding to the new environment trigger convention.

## Management Group Hierarchy

Each management group entry:
```
{
  "name": "mg-platform-dev",
  "display_name": "Platform Development",
  "parent_id": "mg-platform"
}
```
Root groups use `parent_id: null`.

## Key Terraform Locals

- `tenant_config` / `management_groups_config`: Raw decoded JSON
- `filtered_subscriptions`: Environment-scoped subscription list
- `merged_config`: Aggregated structure consumed by resources

## Outputs

Important outputs include:
- `management_groups` map of created groups
- `subscriptions` map with alias/name/workload
- `subscription_management_group_associations`
- `deployment_information` (timestamp, version, environment)

## Example Subscription Entry

```
{
  "name": "Production Workloads",
  "alias": "prod-workloads",
  "management_group_id": "mg-workloads-prod",
  "workload": "Production",
  "environment": "prod"
}
```

## Troubleshooting

- Missing management group: ensure `management_groups.json` has the referenced `name`.
- Empty plan: Verify the `environment` value matches subscription entries.
- Backend lock: Check Azure Storage `tfstate` container for locks.

## Best Practices

- Keep environment logic ONLY in `tenant-config.json` via `environment` field.
- Avoid duplicating subscription definitions.
- Use separate state keys per environment.
- Review plan output in CI before deploying.

## Contributing

1. Branch from `develop`
2. Update JSON / Terraform
3. Run local plan
4. Push → CI validate
5. Open PR to `develop`
6. Merge to `main` for production

## Deprecated

The following are no longer used and have been removed:
- `dev-config.json`
- `prod-config.json`
- Per-environment management group JSON files

Centralization reduces drift and improves auditability.
