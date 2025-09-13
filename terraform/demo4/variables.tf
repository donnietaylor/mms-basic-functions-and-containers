variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-mms-demo4"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Function App variables
variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
  default     = "func-mms-demo4"
}

variable "function_storage_account_name" {
  description = "Name of the storage account for the Function App"
  type        = string
  default     = "stmmsdemo4func"
}

# Container App variables
variable "container_app_name" {
  description = "Name of the Container App"
  type        = string
  default     = "ca-mms-demo4"
}

variable "container_environment_name" {
  description = "Name of the Container Apps Environment"
  type        = string
  default     = "cae-mms-demo4"
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
  default     = "law-mms-demo4"
}

variable "container_registry_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "acrmmsdemo4"
}

# Shared storage for integration
variable "shared_storage_account_name" {
  description = "Name of the shared storage account for integration"
  type        = string
  default     = "stmmsdemo4shared"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "MMS-Demo"
    Demo        = "Demo4"
    Environment = "Development"
    Type        = "Integrated-Solution"
  }
}