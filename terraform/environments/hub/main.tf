variable "resource_group_name" {
  default = "rg-hub-spoke-demo"
}
variable "location" {
  default = "eastus"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "hub_network" {
  source              = "../../modules/network"
  vnet_name           = "vnet-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "AzureFirewallSubnet"      = { address_prefix = "10.0.0.0/26" }
    "ApplicationGatewaySubnet" = { address_prefix = "10.0.1.0/27" }
    "BastionSubnet"            = { address_prefix = "10.0.2.0/27" }
    "GatewaySubnet"            = { address_prefix = "10.0.3.0/27" }
    "ManagementSubnet"         = { address_prefix = "10.0.4.0/24" }
  }
}

module "key_vault" {
  source              = "../../modules/key_vault"
  name                = "kv-hub-shared-12345"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "vpn_gateway" {
  source              = "../../modules/vpn"
  name                = "vpngw-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_subnet_id   = module.hub_network.subnet_ids["GatewaySubnet"]
}
