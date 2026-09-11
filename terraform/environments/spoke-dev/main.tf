variable "resource_group_name" {
  default = "rg-hub-spoke-demo"
}
variable "location" {
  default = "eastus"
}

# 1. READ THE EXISTING HUB (This allows us to connect to it)
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}
data "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_virtual_network_gateway" "hub_vpn" {
  name                = "vpngw-hub"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# 2. BUILD THE DEV SPOKE
module "spoke_network" {
  source              = "../../modules/network"
  vnet_name           = "vnet-dev"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]

  subnets = {
    "WebSubnet"             = { address_prefix = "10.1.1.0/24" }
    "AppSubnet"             = { address_prefix = "10.1.2.0/24" }
    "DBSubnet"              = { address_prefix = "10.1.3.0/24" }
    "ManagementSubnet"      = { address_prefix = "10.1.4.0/24" }
    "PrivateEndpointSubnet" = { address_prefix = "10.1.5.0/24" }
  }
}

# 3. BUILD THE BRIDGE (Spoke to Hub)
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "dev-to-hub"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = module.spoke_network.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id
  use_remote_gateways       = true

  depends_on = [data.azurerm_virtual_network_gateway.hub_vpn]
}

# 4. BUILD THE BRIDGE (Hub to Spoke)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-dev"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id = module.spoke_network.vnet_id
  allow_gateway_transit     = true
}
