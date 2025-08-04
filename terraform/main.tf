terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    # Backend configuration will be provided via Azure DevOps pipeline
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  # Configuration will be inherited from service principal
}
