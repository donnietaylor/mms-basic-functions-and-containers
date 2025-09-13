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

# Create a resource group for the integrated solution
resource "azurerm_resource_group" "demo4" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# === SHARED RESOURCES ===

# Create a shared storage account for integration between Function App and Container App
resource "azurerm_storage_account" "demo4_shared" {
  name                     = var.shared_storage_account_name
  resource_group_name      = azurerm_resource_group.demo4.name
  location                 = azurerm_resource_group.demo4.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable public access for demo purposes
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = true

  tags = var.tags
}

# Create containers for shared data
resource "azurerm_storage_container" "integration_data" {
  name                  = "integration-data"
  storage_account_name  = azurerm_storage_account.demo4_shared.name
  container_access_type = "blob"
}

# Create a Log Analytics Workspace (shared by both services)
resource "azurerm_log_analytics_workspace" "demo4" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.demo4.location
  resource_group_name = azurerm_resource_group.demo4.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# === FUNCTION APP RESOURCES ===

# Create a storage account for the Function App runtime
resource "azurerm_storage_account" "demo4_function" {
  name                     = var.function_storage_account_name
  resource_group_name      = azurerm_resource_group.demo4.name
  location                 = azurerm_resource_group.demo4.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Create an App Service Plan for the Function App
resource "azurerm_service_plan" "demo4_function" {
  name                = "asp-mms-demo4-func"
  resource_group_name = azurerm_resource_group.demo4.name
  location            = azurerm_resource_group.demo4.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
  tags                = var.tags
}

# Create the Function App
resource "azurerm_linux_function_app" "demo4" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.demo4.name
  location            = azurerm_resource_group.demo4.location

  storage_account_name       = azurerm_storage_account.demo4_function.name
  storage_account_access_key = azurerm_storage_account.demo4_function.primary_access_key
  service_plan_id            = azurerm_service_plan.demo4_function.id

  site_config {
    application_stack {
      powershell_core_version = "7.2"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "powershell"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    # Shared storage for integration
    "SharedStorageConnection" = azurerm_storage_account.demo4_shared.primary_connection_string
    # Container App URL (will be updated after container deployment)
    "CONTAINER_APP_URL" = "https://${var.container_app_name}.${var.location}.azurecontainerapps.io"
  }

  tags = var.tags
}

# === CONTAINER APP RESOURCES ===

# Create Azure Container Registry
resource "azurerm_container_registry" "demo4" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.demo4.name
  location            = azurerm_resource_group.demo4.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

# Create Container Apps Environment
resource "azurerm_container_app_environment" "demo4" {
  name                       = var.container_environment_name
  location                   = azurerm_resource_group.demo4.location
  resource_group_name        = azurerm_resource_group.demo4.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo4.id
  tags                       = var.tags
}

# Create the Container App
resource "azurerm_container_app" "demo4" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.demo4.id
  resource_group_name          = azurerm_resource_group.demo4.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    container {
      name   = "demo4-integrated-api"
      image  = "mcr.microsoft.com/powershell:7.2-ubuntu-20.04" # Placeholder - will be updated in workflow
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name  = "FUNCTION_APP_URL"
        value = "https://${azurerm_linux_function_app.demo4.default_hostname}"
      }

      env {
        name  = "SHARED_STORAGE_CONNECTION"
        value = azurerm_storage_account.demo4_shared.primary_connection_string
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080
    transport                  = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # System-assigned identity for integration
  identity {
    type = "SystemAssigned"
  }
}

# Grant Container App managed identity permission to pull from ACR
resource "azurerm_role_assignment" "container_app_acr_pull" {
  scope                = azurerm_container_registry.demo4.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.demo4.identity[0].principal_id
}