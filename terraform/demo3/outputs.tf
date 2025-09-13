output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.demo3.name
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.demo3.name
}

output "container_app_url" {
  description = "URL of the Container App"
  value       = "https://${azurerm_container_app.demo3.ingress[0].fqdn}"
}

output "container_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.demo3.name
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.demo3.name
}

output "container_registry_login_server" {
  description = "Login server URL for the container registry"
  value       = azurerm_container_registry.demo3.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the container registry"
  value       = azurerm_container_registry.demo3.admin_username
}

output "container_registry_admin_password" {
  description = "Admin password for the container registry"
  value       = azurerm_container_registry.demo3.admin_password
  sensitive   = true
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.demo3.name
}