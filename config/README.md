# Management Group Structure

This directory contains the JSON configuration files that define the Azure tenant structure, management groups and subscriptions.

## Management Group Hierarchy

The management group hierarchy is structured as follows:
- `mg-root` (Root Management Group) - Defined in management-groups.json
  - `mg-platform-dev` (Platform - Development) - Defined in management-groups-dev.json
  - `mg-workloads-dev` (Workloads - Development) - Defined in management-groups-dev.json
  - `mg-workloads-prod` (Workloads - Production) - Defined in management-groups-prod.json

## File Structure

The configuration is split into multiple files to provide a single source of truth for management group hierarchy while allowing environment-specific subscription configurations:

### Base Management Group Structure
- `management-groups.json` - The primary management group hierarchy that applies across all environments (includes `mg-root`)
- `management-groups-dev.json` - Additional development-specific management groups
- `management-groups-prod.json` - Additional production-specific management groups

### Environment-Specific Configurations
- `dev-config.json` - Development tenant settings and subscriptions
- `prod-config.json` - Production tenant settings and subscriptions

## Usage

The Terraform configuration will automatically:
1. Load the base management groups from `management-groups.json`
2. Load any environment-specific management groups if present
3. Combine these with the environment-specific subscription configuration

## Example Command

```bash
terraform apply \
  -var-file="../config/prod-config.json" \
  -var="environment=prod" \
  -var="management_groups_file=../config/management-groups.json"
```

## Benefits

This structure provides:
- A single source of truth for management group hierarchy
- Consistent structure across environments
- Environment-specific overrides when needed
- Separation of structure (management groups) from resources (subscriptions)
- Clear definition of the root management group (`mg-root`) in the base configuration file
