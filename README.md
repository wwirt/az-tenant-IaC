# Azure Tenant Infrastructure as Code (IaC)

This project implements Azure DevOps CI/CD pipelines for deploying Azure tenant infrastructure using Terraform and JSON configuration files.

## Overview

This solution provides:
- Azure DevOps CI/CD pipeline for automated deployment
- Terraform infrastructure as code for Azure tenant, management groups, and subscriptions
- JSON-based configuration for different environments
- Validation and deployment stages
- Support for multiple environments (dev, prod)

## Project Structure

```
.
├── azure-pipelines.yml          # Azure DevOps CI/CD pipeline
├── config/                      # JSON configuration files
│   ├── dev-config.json         # Development environment config
│   ├── prod-config.json        # Production environment config
│   └── tenant-config.json      # Base tenant configuration
├── terraform/                   # Terraform infrastructure code
│   ├── main.tf                 # Provider configuration
│   ├── variables.tf            # Variable definitions
│   ├── locals.tf               # Local values and JSON processing
│   ├── tenant.tf               # Main tenant infrastructure
│   └── outputs.tf              # Output definitions
└── README.md                   # This file
```

## Prerequisites

### Azure Setup

1. **Azure Subscription**: You need an Azure subscription with appropriate permissions
2. **Service Principal**: Create a service principal with the following permissions:
   - `Owner` or `Contributor` at the tenant level
   - `Application Administrator` in Azure AD
   - `Directory Writers` in Azure AD

3. **Storage Account**: Create a storage account for Terraform state:
   ```bash
   az group create --name terraform-state-rg --location "East US"
   az storage account create --resource-group terraform-state-rg --name terraformstatestore001 --sku Standard_LRS --encryption-services blob
   az storage container create --name tfstate --account-name terraformstatestore001
   ```

### Azure DevOps Setup

1. **Project**: Create an Azure DevOps project
2. **Service Connection**: 
   - Go to Project Settings > Service connections
   - Create a new Azure Resource Manager service connection
   - Use the service principal created above
   - Name it `azure-service-connection` (or update the pipeline variable)

3. **Environments**: Create environments in Azure DevOps:
   - `development`
   - `production`

4. **Variable Groups** (Optional): Create variable groups for sensitive information

## Configuration

### Update Pipeline Variables

Edit `azure-pipelines.yml` and update:
- `azureServiceConnection`: Name of your Azure service connection
- `backendAzureRmStorageAccountName`: Your Terraform state storage account name
- `backendAzureRmResourceGroupName`: Resource group containing the storage account

### JSON Configuration Files

The JSON configuration files in the `config/` directory define your tenant structure:

#### Structure:
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
    }
  ],
  "subscriptions": [
    {
      "name": "Subscription Name",
      "alias": "subscription-alias",
      "management_group_id": "mg-root",
      "workload": "Production"
    }
  ]
}
```

## Deployment

### Automatic Deployment

The pipeline automatically triggers on:
- Push to `main` branch → Production deployment
- Push to `develop` branch → Development deployment

### Manual Deployment

1. **Local Development**:
   ```bash
   cd terraform
   terraform init
   terraform plan -var-file="../config/dev-config.json"
   terraform apply -var-file="../config/dev-config.json"
   ```

2. **Environment-specific deployment**:
   ```bash
   # Development
   terraform apply -var-file="../config/dev-config.json" -var="environment=dev"
   
   # Production
   terraform apply -var-file="../config/prod-config.json" -var="environment=prod"
   ```

## Pipeline Stages

### 1. Validate
- **ValidateConfig**: Validates JSON configuration files
- **TerraformValidate**: Runs `terraform validate` and `terraform plan`

### 2. Deploy_Dev
- Deploys to development environment
- Triggered on `develop` branch
- Uses `dev-config.json`

### 3. Deploy_Prod
- Deploys to production environment
- Triggered on `main` branch
- Uses `prod-config.json`

## Security Considerations

1. **Service Principal Permissions**: Use least privilege principle
2. **State File Security**: Terraform state is stored in Azure Storage with encryption
3. **Secrets Management**: Use Azure Key Vault for sensitive information
4. **Environment Separation**: Different state files for different environments

## Customization

### Adding New Environments

1. Create a new JSON config file in `config/` directory
2. Add a new stage in `azure-pipelines.yml`
3. Create the environment in Azure DevOps

### Modifying Infrastructure

1. Update the JSON configuration files for your requirements
2. Modify Terraform code in the `terraform/` directory if needed
3. Test changes in development environment first

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure service principal has sufficient permissions
2. **State Lock**: If deployment fails, check for state locks in Azure Storage
3. **Resource Conflicts**: Ensure resource names are unique across Azure

### Debugging

- Check Azure DevOps pipeline logs
- Review Terraform plan output
- Validate JSON configuration files locally

## Best Practices

1. **Version Control**: Always commit changes through Git
2. **Testing**: Test in development before promoting to production
3. **Documentation**: Keep configuration files well-documented
4. **Monitoring**: Set up monitoring and alerting for infrastructure changes

## Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Test in development environment
4. Create a pull request to `develop`
5. After approval, merge to `main` for production deployment
