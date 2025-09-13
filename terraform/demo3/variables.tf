variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-mms-demo3"
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

variable "container_app_name" {
  description = "Name of the Container App"
  type        = string
  default     = "ca-mms-demo3"
}

variable "container_environment_name" {
  description = "Name of the Container Apps Environment"
  type        = string
  default     = "cae-mms-demo3"
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
  default     = "law-mms-demo3"
}

variable "container_registry_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "acrmmsdemo3"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "MMS-Demo"
    Demo        = "Demo3"
    Environment = "Development"
  }
}