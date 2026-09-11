variable "resource_group_name" {
  type        = string
  default     = "rg-hub-spoke-demo"
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region"
}
