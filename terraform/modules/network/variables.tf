variable "vnet_name" {
  type        = string
  description = "The name of the virtual network"
}

variable "location" {
  type        = string
  description = "The Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "address_space" {
  type        = list(string)
  description = "The address space for the VNet"
}

variable "subnets" {
  type = map(object({
    address_prefix = string
  }))
  description = "A map of subnets to create. Key is the subnet name, value is an object containing address_prefix."
}
