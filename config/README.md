# Tenant Configuration

This directory contains the YAML configuration file that defines the Azure tenant structure, management groups, and subscriptions.

## Structure

The `tenant.yml` file is the single source of truth for the tenant configuration. It has three main sections:

- `tenant`: Defines the tenant's display name and domain.
- `management_groups`: A list of all management groups in the hierarchy. Each management group has a `name`, `display_name`, and `parent_id`. The root management group's `parent_id` should be `null`.
- `subscriptions`: A list of all subscriptions, including their `name`, `alias`, `management_group_id`, `workload`, and `environment`.

## Usage

The Terraform configuration will automatically load the `tenant.yml` file and provision the resources accordingly. You can filter which subscriptions are deployed by setting the `environment` variable in your Terraform command or `.tfvars` file.

## Example Command

```bash
terraform apply -var="environment=prod"
```

## Benefits

This centralized structure provides:
- A single source of truth for the entire tenant configuration.
- A clear and consistent structure.
- Simplified management and maintenance.
- Reduced risk of configuration drift and errors.
- Environment-specific deployments from a single configuration file.
