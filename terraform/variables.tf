variable "config_file_path" {
  description = "Path to the environment-specific JSON configuration file"
  type        = string
  default     = ""
}

variable "management_groups_file" {
  description = "Path to the management groups JSON configuration file"
  type        = string
  default     = ""
}

variable "tenant_display_name" {
  description = "Default tenant display name if not specified in config"
  type        = string
  default     = "Default Tenant"
}

variable "tenant_domain_name" {
  description = "Default tenant domain name if not specified in config"
  type        = string
  default     = "defaulttenant.onmicrosoft.com"
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "prod", "production", "development", "staging", "sandbox"], lower(var.environment))
    error_message = "Environment must be one of: dev, test, prod, production, development, staging, sandbox."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "deployment_version" {
  description = "Version of the deployment, used for tagging"
  type        = string
  default     = "1.0.0"
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings for resources"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment   = "dev"
    ManagedBy     = "Terraform"
    Project       = "Azure-Tenant-IaC"
    CreatedBy     = "Azure-DevOps"
    CostCenter    = "IT-Cloud"
  }
  
  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[a-zA-Z0-9._-]+$", k)) && can(regex("^[a-zA-Z0-9._-]+$", v))
    ])
    error_message = "Tag keys and values must contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}

variable "tenant_config_file" {
  description = "Path to the tenant configuration JSON file"
  type        = string
  default     = ""
}

variable "security_level_validation" {
  description = "Enable validation of security levels in configuration"
  type        = bool
  default     = true
}
