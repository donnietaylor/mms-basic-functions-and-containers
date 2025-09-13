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
resource "azurerm_resource_group" "demo2" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create a storage account for the Function App runtime
resource "azurerm_storage_account" "demo2_function" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.demo2.name
  location                 = azurerm_resource_group.demo2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Create an additional storage account for data storage demo
resource "azurerm_storage_account" "demo2_data" {
  name                     = var.data_storage_account_name
  resource_group_name      = azurerm_resource_group.demo2.name
  location                 = azurerm_resource_group.demo2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Enable public access for demo purposes
  public_network_access_enabled = true
  allow_nested_items_to_be_public = true
  
  tags = var.tags
}

# Create a blob container for demo messages
resource "azurerm_storage_container" "demo_messages" {
  name                  = "demo-messages"
  storage_account_name  = azurerm_storage_account.demo2_data.name
  container_access_type = "blob"  # Public read access for demo
}

# Create an App Service Plan
resource "azurerm_service_plan" "demo2" {
  name                = "asp-mms-demo2"
  resource_group_name = azurerm_resource_group.demo2.name
  location            = azurerm_resource_group.demo2.location
  os_type             = "Linux"
  sku_name            = "Y1"  # Consumption plan
  tags                = var.tags
}

# Create the Function App
resource "azurerm_linux_function_app" "demo2" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.demo2.name
  location            = azurerm_resource_group.demo2.location

  storage_account_name       = azurerm_storage_account.demo2_function.name
  storage_account_access_key = azurerm_storage_account.demo2_function.primary_access_key
  service_plan_id            = azurerm_service_plan.demo2.id

  site_config {
    application_stack {
      powershell_core_version = "7.2"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "powershell"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    # Connection string for the data storage account
    "DataStorageConnection" = azurerm_storage_account.demo2_data.primary_connection_string
  }

  tags = var.tags
}