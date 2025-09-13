output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.demo1.name
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.demo1.name
}

output "function_app_url" {
  description = "Default hostname of the Function App"
  value       = "https://${azurerm_linux_function_app.demo1.default_hostname}"
}

output "function_app_trigger_url" {
  description = "URL to trigger the HTTP function"
  value       = "https://${azurerm_linux_function_app.demo1.default_hostname}/api/HttpTrigger"
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.demo1.name
}