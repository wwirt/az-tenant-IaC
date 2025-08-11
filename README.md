# Azure Tenant Infrastructure as Code (IaC)

## Overview

This repository contains Infrastructure as Code (IaC) for provisioning and managing Azure tenant-level resources including management groups, subscriptions, and security policies. The solution implements CIS Azure Benchmark compliance controls and follows security best practices.

## Architecture

```
Azure Tenant Root
├── mg-root (Root Management Group)
    ├── mg-security (Security Management Group)
    ├── mg-platform (Platform Management Group)
    │   ├── mg-platform-dev (Platform Development)
    │   └── mg-platform-prod (Platform Production)
    ├── mg-workloads (Workloads Management Group)
    │   ├── mg-workloads-dev (Workloads Development)
    │   └── mg-workloads-prod (Workloads Production)
    ├── mg-sandbox (Sandbox Management Group)
    └── mg-quarantine (Quarantine Management Group)
```

## Key Features

- **Management Group Hierarchy**: Structured organization following Azure best practices
- **CIS Compliance**: Automated validation against CIS Azure Benchmark controls
- **Security Hardening**: Tenant-level security policies and controls
- **Multi-Environment Support**: Separate dev and production deployments
- **Azure Policy Integration**: Built-in policy assignments for governance
- **Defender for Cloud**: Enhanced security monitoring and threat detection

## Repository Structure

```
├── config/                     # Configuration files
│   ├── tenant-config.json     # Main tenant configuration
│   ├── management-groups.json # Management group structure
│   └── tenant-template.json   # Configuration template
├── terraform/                 # Terraform configuration
│   ├── main.tf               # Provider configuration
│   ├── variables.tf          # Variable definitions
│   ├── locals.tf             # Local values and data processing
│   └── tenant.tf             # Tenant resource definitions
├── azure-pipelines-ci.yml    # CI pipeline with validation
├── azure-pipelines-cd.yml    # CD pipeline for deployment
└── README.md                 # This file
```

## Getting Started

### Prerequisites

- Azure subscription with tenant-level permissions
- Azure DevOps organization
- Service principal with appropriate permissions:
  - Management Group Contributor
  - User Access Administrator
  - Security Admin

### Quick Start

1. Clone this repository
2. Configure service connections in Azure DevOps
3. Update configuration files in the `config/` directory
4. Run the CI pipeline to validate configuration
5. Deploy using the CD pipeline

## Configuration Guide

### Configuration Files Overview

The solution uses JSON configuration files to define tenant settings, management groups, security policies, and subscription assignments.

### tenant-config.json Structure

```json
{
  "tenant": {
    "display_name": "Contoso Tenant",
    "domain_name": "contoso.onmicrosoft.com",
    "security_contact": "security@contoso.com"
  },
  "security_policies": {
    "cis_controls": { ... },
    "azure_policies": { ... },
    "monitoring": { ... }
  },
  "subscriptions": [ ... ]
}
```

#### Tenant Section

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| `display_name` | Human-readable tenant name | Yes | "Contoso Tenant" |
| `domain_name` | Primary domain for the tenant | Yes | "contoso.onmicrosoft.com" |
| `security_contact` | Email for security notifications | Yes | "security@contoso.com" |

#### Security Policies Section

##### CIS Controls
- `require_mfa_for_all_users`: Enforce MFA (CIS 1.1)
- `block_legacy_authentication`: Block legacy auth (CIS 1.2)
- `minimum_password_length`: Password complexity (CIS 1.3) - minimum 14 characters
- `require_managed_devices`: Device compliance requirement
- `block_high_risk_sign_ins`: Conditional access for high-risk sign-ins
- `require_terms_of_use`: Terms of use enforcement

##### Azure Policies
- `allowed_locations`: Permitted Azure regions (e.g., ["West Europe", "North Europe"])
- `deny_public_storage_accounts`: Block public storage access (CIS 3.2)
- `require_https_traffic_only`: HTTPS-only enforcement (CIS 3.1)
- `deny_insecure_tls`: Block insecure TLS versions
- `require_storage_encryption`: Storage encryption requirement
- `deny_rdp_from_internet`: Block RDP from internet (CIS 6.1)
- `deny_ssh_from_internet`: Block SSH from internet (CIS 6.2)
- `require_nsg_on_subnets`: Network security group requirement
- `audit_vm_without_backup`: Audit VMs without backup

##### Monitoring
- `enable_defender_for_cloud`: Enable Defender for Cloud (CIS 2.1)
- `enable_activity_log_alerts`: Activity log monitoring
- `log_retention_days`: Log retention period (minimum 90 days)

#### Subscriptions Section

```json
{
  "name": "Platform Services",
  "alias": "platform-services",
  "management_group_id": "mg-platform-dev",
  "workload": "Development",
  "security_level": "Medium"
}
```

| Field | Description | Values |
|-------|-------------|--------|
| `name` | Subscription display name | String |
| `alias` | Unique identifier | String (no spaces) |
| `management_group_id` | Target management group | Must exist in management-groups.json |
| `workload` | Workload type | Development, Production |
| `security_level` | Security classification | Low, Medium, High, Critical |

### management-groups.json Structure

```json
{
  "tenant": {
    "display_name": "Contoso Enterprise",
    "domain_name": "contoso.onmicrosoft.com"
  },
  "management_groups": [
    {
      "name": "mg-root",
      "display_name": "Root Management Group",
      "parent_id": null
    }
  ]
}
```

#### Management Group Properties

| Field | Description | Required |
|-------|-------------|----------|
| `name` | Unique management group identifier | Yes |
| `display_name` | Human-readable name | Yes |
| `parent_id` | Parent management group name | No (null for root) |

### Configuration Validation

The CI pipeline validates:

1. **JSON Syntax**: All files must be valid JSON
2. **Schema Validation**: Required fields must be present
3. **Reference Integrity**: Management group references must exist
4. **CIS Compliance**: Security controls must be properly configured
5. **Hierarchical Structure**: Management group parent-child relationships

## Security & Compliance Guide

### CIS Azure Benchmark Implementation

This solution implements key CIS Azure Benchmark v1.4.0 controls:

#### Identity and Access Management

**CIS 1.1 - Multi-Factor Authentication**
- Enforces MFA for all users through conditional access policies
- Configuration: `security_policies.cis_controls.require_mfa_for_all_users: true`

**CIS 1.2 - Legacy Authentication**
- Blocks legacy authentication protocols
- Configuration: `security_policies.cis_controls.block_legacy_authentication: true`

**CIS 1.3 - Password Policy**
- Enforces minimum password length of 14 characters
- Configuration: `security_policies.cis_controls.minimum_password_length: 14`

#### Security Center

**CIS 2.1 - Defender for Cloud**
- Enables Defender for Cloud Standard tier on all subscriptions
- Configuration: `security_policies.monitoring.enable_defender_for_cloud: true`

#### Storage Accounts

**CIS 3.1 - Secure Transfer**
- Requires HTTPS traffic only for storage accounts
- Azure Policy: "Secure transfer to storage accounts should be enabled"
- Configuration: `security_policies.azure_policies.require_https_traffic_only: true`

**CIS 3.2 - Public Access**
- Denies public network access to storage accounts
- Azure Policy: "Storage accounts should restrict network access"
- Configuration: `security_policies.azure_policies.deny_public_storage_accounts: true`

#### Network Security

**CIS 6.1 - RDP Access**
- Blocks RDP access from the internet
- Azure Policy: "RDP access from the Internet should be blocked"
- Configuration: `security_policies.azure_policies.deny_rdp_from_internet: true`

**CIS 6.2 - SSH Access**
- Blocks SSH access from the internet
- Azure Policy: "SSH access from the Internet should be blocked"
- Configuration: `security_policies.azure_policies.deny_ssh_from_internet: true`

### Management Group Security Structure

#### Security Management Group (mg-security)
- Dedicated for security operations and monitoring
- Hosts security-related subscriptions
- Applies strictest security policies

#### Quarantine Management Group (mg-quarantine)
- Isolates compromised or suspicious resources
- Minimal permissions and restricted policies
- Used for incident response and investigation

#### Platform Management Groups
- **mg-platform-dev**: Development platform services
- **mg-platform-prod**: Production platform services
- Separate policies based on environment criticality

#### Workload Management Groups
- **mg-workloads-dev**: Development workloads
- **mg-workloads-prod**: Production workloads
- Environment-specific governance and policies

### Azure Policy Assignments

The solution automatically assigns these Azure Policies at the tenant root level:

1. **CIS Microsoft Azure Foundations Benchmark v1.4.0**
   - Comprehensive policy initiative covering all CIS controls
   - Applied to mg-root management group

2. **Allowed Locations**
   - Restricts resource deployment to approved Azure regions
   - Prevents data residency violations

3. **Storage Security Policies**
   - Requires HTTPS traffic only
   - Denies public storage account access
   - Enforces storage encryption

4. **Network Security Policies**
   - Blocks RDP/SSH access from internet
   - Requires Network Security Groups on subnets

### Security Monitoring

#### Defender for Cloud
- Standard tier enabled on all subscriptions
- Continuous security assessment
- Threat detection and response
- Security recommendations and alerts

#### Activity Log Monitoring
- 90-day log retention minimum
- Activity log alerts for critical changes
- Integration with Azure Monitor

### Compliance Validation

The CI pipeline performs automated compliance checks:

```powershell
# Example validation checks
- MFA enforcement enabled
- Legacy authentication blocked
- Password policy compliance
- Defender for Cloud enabled
- Storage security policies
- Network access restrictions
- Management group structure validation
```

## Deployment Guide

### Pipeline Overview

The solution uses Azure DevOps pipelines for CI/CD:

- **CI Pipeline** (`azure-pipelines-ci.yml`): Validates JSON configuration and Terraform code
- **CD Pipeline** (`azure-pipelines-cd.yml`): Deploys to development and production environments

### Service Connections Required

1. **terraform-backend-connection**
   - Access to Terraform state storage account
   - Storage Blob Data Contributor role

2. **tenant-management-connection**
   - Tenant-level permissions for resource deployment
   - Management Group Contributor
   - User Access Administrator
   - Security Admin

### Pipeline Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `terraformVersion` | Terraform version to use | '1.5.0' |
| `backendResourceGroup` | Resource group for state storage | 'terraform-state-rg' |
| `backendStorageAccount` | Storage account for state files | 'terraformstatestore001' |
| `workingDirectory` | Terraform working directory | '$(System.DefaultWorkingDirectory)/terraform' |
| `configDirectory` | Configuration files directory | '$(System.DefaultWorkingDirectory)/config' |

### Pipeline Stages

#### 1. Validate Stage
- **ValidateConfig Job**: Validates JSON configuration files
- **CIS Compliance Validation**: Checks CIS benchmark compliance
- **TerraformValidate Job**: Runs `terraform validate` and `terraform plan`

#### 2. Deploy_Dev Stage
- Deploys to development environment
- Triggered on `develop` branch commits
- Uses development-specific configuration
- State file: `tenant-dev.tfstate`

#### 3. Deploy_Prod Stage
- Deploys to production environment
- Triggered on `main` branch commits
- Uses production-specific configuration
- State file: `tenant-prod.tfstate`
- Enhanced validation and verification

### Manual Deployment

For local development or troubleshooting:

```bash
# Initialize Terraform
terraform init -backend-config="resource_group_name=terraform-state-rg" \
               -backend-config="storage_account_name=terraformstatestore001" \
               -backend-config="container_name=tfstate" \
               -backend-config="key=tenant-dev.tfstate"

# Plan deployment
terraform plan -var="environment=dev" \
               -var="management_groups_file=../config/management-groups.json" \
               -var="tenant_config_file=../config/tenant-config.json"

# Apply changes
terraform apply -var="environment=dev" \
                -var="management_groups_file=../config/management-groups.json" \
                -var="tenant_config_file=../config/tenant-config.json"
```

## Troubleshooting

### Common Issues

1. **JSON Syntax Errors**
   - Validate JSON files using online validators
   - Check for missing commas, brackets, or quotes
   - Remove trailing commas

2. **Permission Errors**
   - Ensure service principal has sufficient tenant-level permissions
   - Verify Management Group Contributor role assignment
   - Check User Access Administrator permissions

3. **State Lock Issues**
   - If deployment fails, check for state locks in Azure Storage
   - Manually release locks if necessary: `terraform force-unlock <lock-id>`

4. **CIS Compliance Validation Failures**
   - Review the specific CIS control that's failing
   - Update tenant-config.json to meet requirements
   - Ensure all required security policies are enabled

### Debugging Pipeline Issues

1. **Check Azure DevOps Logs**
   - Review pipeline execution logs
   - Look for specific error messages in failed tasks

2. **Validate Configuration Locally**
   ```powershell
   # Test JSON parsing
   Get-Content "config/tenant-config.json" | ConvertFrom-Json
   Get-Content "config/management-groups.json" | ConvertFrom-Json
   ```

3. **Terraform Validation**
   ```bash
   # Run terraform commands locally
   terraform validate
   terraform plan -detailed-exitcode
   ```

## Best Practices

### Configuration Management
1. **Version Control**: Always commit configuration changes through Git
2. **Testing**: Validate changes in development before production
3. **Documentation**: Document any custom configurations or deviations
4. **Backup**: Maintain backups of working configurations

### Security
1. **Least Privilege**: Use minimal required permissions for service principals
2. **Secrets Management**: Store sensitive values in Azure Key Vault
3. **Monitoring**: Set up alerts for configuration changes
4. **Regular Reviews**: Periodically review and update security policies

### Operations
1. **State Management**: Protect Terraform state files with appropriate access controls
2. **Environment Separation**: Use separate state files for different environments
3. **Change Management**: Use pull requests for all configuration changes
4. **Monitoring**: Monitor pipeline executions and deployment results

## Contributing

1. **Create Feature Branch**: Branch from `develop` for new features
2. **Make Changes**: Update configuration files or Terraform code
3. **Test Locally**: Validate JSON and run terraform plan
4. **Submit PR**: Create pull request with clear description
5. **CI Validation**: Ensure all CI checks pass
6. **Code Review**: Address review comments
7. **Merge**: Merge to `develop`, then `main` for production

## Support and Contact

- **Issues**: Create GitHub issues for bugs or feature requests
- **Security Questions**: Contact security team for compliance-related queries
- **Documentation**: Refer to Azure documentation for platform-specific guidance
- **Emergency**: Follow your organization's incident response procedures

## License

This project is licensed under the MIT License - see the LICENSE file for details.
