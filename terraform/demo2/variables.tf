variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-mms-demo2"
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

variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
  default     = "func-mms-demo2"
}

variable "storage_account_name" {
  description = "Name of the storage account for the Function App"
  type        = string
  default     = "stmmsdemo2"
}

variable "data_storage_account_name" {
  description = "Name of the additional storage account for data"
  type        = string
  default     = "stdatamms2"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "MMS-Demo"
    Demo        = "Demo2"
    Environment = "Development"
  }
}