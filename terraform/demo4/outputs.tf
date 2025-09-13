output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.demo4.name
}

# Function App outputs
output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.demo4.name
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${azurerm_linux_function_app.demo4.default_hostname}"
}

output "function_app_trigger_url" {
  description = "URL to trigger the HTTP function"
  value       = "https://${azurerm_linux_function_app.demo4.default_hostname}/api/HttpTrigger"
}

# Container App outputs
output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.demo4.name
}

output "container_app_url" {
  description = "URL of the Container App"
  value       = "https://${azurerm_container_app.demo4.ingress[0].fqdn}"
}

output "container_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.demo4.name
}

# Registry outputs
output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.demo4.name
}

output "container_registry_login_server" {
  description = "Login server URL for the container registry"
  value       = azurerm_container_registry.demo4.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the container registry"
  value       = azurerm_container_registry.demo4.admin_username
}

output "container_registry_admin_password" {
  description = "Admin password for the container registry"
  value       = azurerm_container_registry.demo4.admin_password
  sensitive   = true
}

# Shared resources outputs
output "shared_storage_account_name" {
  description = "Name of the shared storage account"
  value       = azurerm_storage_account.demo4_shared.name
}

output "shared_storage_connection_string" {
  description = "Connection string for the shared storage account"
  value       = azurerm_storage_account.demo4_shared.primary_connection_string
  sensitive   = true
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.demo4.name
}

# Integration URLs
output "integration_test_urls" {
  description = "URLs for testing the integration between services"
  value = {
    function_app = "https://${azurerm_linux_function_app.demo4.default_hostname}/api/HttpTrigger?name=IntegrationTest"
    container_app = "https://${azurerm_container_app.demo4.ingress[0].fqdn}/"
    container_integration = "https://${azurerm_container_app.demo4.ingress[0].fqdn}/integration"
  }
}