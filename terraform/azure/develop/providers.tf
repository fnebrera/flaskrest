# Descripción: Ejemplo de configuración de providers en Terraform para Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.37.0"
    }
  }

  # El estado se mantiene en remoto mediante http
  backend "http" {
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.HYPERVISOR_HOST
  client_id       = var.HYPERVISOR_USER
  client_secret   = var.HYPERVISOR_PASSWD
  tenant_id       = var.HYPERVISOR_TENANT
}


