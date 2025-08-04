variable "config_file_path" {
  description = "Path to the JSON configuration file"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment   = "dev"
    ManagedBy     = "Terraform"
    Project       = "Azure-Tenant-IaC"
    CreatedBy     = "Azure-DevOps"
  }
}
