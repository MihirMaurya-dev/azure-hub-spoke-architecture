variable "name" {
  type        = string
  description = "Name of the VPN Gateway"
}

variable "location" {
  type        = string
  description = "The Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "gateway_subnet_id" {
  type        = string
  description = "The ID of the GatewaySubnet"
}
