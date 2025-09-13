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
resource "azurerm_resource_group" "demo3" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create a Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "demo3" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.demo3.location
  resource_group_name = azurerm_resource_group.demo3.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Create Azure Container Registry
resource "azurerm_container_registry" "demo3" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.demo3.name
  location            = azurerm_resource_group.demo3.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

# Create Container Apps Environment
resource "azurerm_container_app_environment" "demo3" {
  name                       = var.container_environment_name
  location                   = azurerm_resource_group.demo3.location
  resource_group_name        = azurerm_resource_group.demo3.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo3.id
  tags                       = var.tags
}

# Create the Container App
resource "azurerm_container_app" "demo3" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.demo3.id
  resource_group_name          = azurerm_resource_group.demo3.name
  revision_mode               = "Single"
  tags                        = var.tags

  template {
    container {
      name   = "demo3-api"
      image  = "mcr.microsoft.com/powershell:7.2-ubuntu-20.04"  # Placeholder - will be updated in workflow
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "PORT"
        value = "8080"
      }
    }

    min_replicas = 0
    max_replicas = 1
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 8080
    transport                = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Simplified identity for demo purposes
  identity {
    type = "SystemAssigned"
  }
}