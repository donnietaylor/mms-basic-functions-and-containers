# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "demo1" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create a storage account for the Function App
resource "azurerm_storage_account" "demo1" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.demo1.name
  location                 = azurerm_resource_group.demo1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Create an App Service Plan
resource "azurerm_service_plan" "demo1" {
  name                = "asp-mms-demo1"
  resource_group_name = azurerm_resource_group.demo1.name
  location            = azurerm_resource_group.demo1.location
  os_type             = "Linux"
  sku_name            = "Y1"  # Consumption plan
  tags                = var.tags
}

# Create the Function App
resource "azurerm_linux_function_app" "demo1" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.demo1.name
  location            = azurerm_resource_group.demo1.location

  storage_account_name       = azurerm_storage_account.demo1.name
  storage_account_access_key = azurerm_storage_account.demo1.primary_access_key
  service_plan_id            = azurerm_service_plan.demo1.id

  site_config {
    application_stack {
      powershell_core_version = "7.2"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "powershell"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  tags = var.tags
}