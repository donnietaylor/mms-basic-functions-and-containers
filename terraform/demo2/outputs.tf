output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.demo2.name
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.demo2.name
}

output "function_app_url" {
  description = "Default hostname of the Function App"
  value       = "https://${azurerm_linux_function_app.demo2.default_hostname}"
}

output "function_app_trigger_url" {
  description = "URL to trigger the HTTP function"
  value       = "https://${azurerm_linux_function_app.demo2.default_hostname}/api/HttpTrigger"
}

output "function_storage_account_name" {
  description = "Name of the function runtime storage account"
  value       = azurerm_storage_account.demo2_function.name
}

output "data_storage_account_name" {
  description = "Name of the data storage account"
  value       = azurerm_storage_account.demo2_data.name
}

output "data_storage_connection_string" {
  description = "Connection string for the data storage account"
  value       = azurerm_storage_account.demo2_data.primary_connection_string
  sensitive   = true
}

output "demo_container_url" {
  description = "URL of the demo messages container"
  value       = "https://${azurerm_storage_account.demo2_data.name}.blob.core.windows.net/demo-messages"
}