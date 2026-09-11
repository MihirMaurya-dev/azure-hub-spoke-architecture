resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ==========================================
# HUB NETWORK
# ==========================================
module "hub_network" {
  source              = "./modules/network"
  vnet_name           = "vnet-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  # for_each is used inside the network module to dynamically create these subnets
  subnets = {
    "AzureFirewallSubnet"      = { address_prefix = "10.0.0.0/26" }
    "ApplicationGatewaySubnet" = { address_prefix = "10.0.1.0/27" }
    "BastionSubnet"            = { address_prefix = "10.0.2.0/27" }
    "GatewaySubnet"            = { address_prefix = "10.0.3.0/27" }
    "ManagementSubnet"         = { address_prefix = "10.0.4.0/24" }
  }
}

# ==========================================
# SPOKE NETWORKS (Using for_each)
# ==========================================
locals {
  spokes = {
    "dev" = {
      address_space = ["10.1.0.0/16"]
      subnets = {
        "WebSubnet"             = { address_prefix = "10.1.1.0/24" }
        "AppSubnet"             = { address_prefix = "10.1.2.0/24" }
        "DBSubnet"              = { address_prefix = "10.1.3.0/24" }
        "ManagementSubnet"      = { address_prefix = "10.1.4.0/24" }
        "PrivateEndpointSubnet" = { address_prefix = "10.1.5.0/24" }
      }
    }
    "prod" = {
      address_space = ["10.2.0.0/16"]
      subnets = {
        "WebSubnet"             = { address_prefix = "10.2.1.0/24" }
        "AppSubnet"             = { address_prefix = "10.2.2.0/24" }
        "DBSubnet"              = { address_prefix = "10.2.3.0/24" }
        "ManagementSubnet"      = { address_prefix = "10.2.4.0/24" }
        "PrivateEndpointSubnet" = { address_prefix = "10.2.5.0/24" }
      }
    }
  }
}

module "spoke_networks" {
  source   = "./modules/network"
  for_each = local.spokes

  vnet_name           = "vnet-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = each.value.address_space
  subnets             = each.value.subnets
}

# ==========================================
# VNET PEERINGS (Hub <-> Spokes)
# ==========================================
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = local.spokes
  name                      = "hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.hub_network.vnet_name
  remote_virtual_network_id = module.spoke_networks[each.key].vnet_id
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = local.spokes
  name                      = "${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.spoke_networks[each.key].vnet_name
  remote_virtual_network_id = module.hub_network.vnet_id
  use_remote_gateways       = true

  # Ensure the VPN gateway exists before using remote gateways in peering
  depends_on = [module.vpn_gateway]
}

# ==========================================
# SHARED RESOURCES IN HUB
# ==========================================
module "key_vault" {
  source              = "./modules/key_vault"
  name                = "kv-hub-shared-12345" # Ensure globally unique name in practice
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "vpn_gateway" {
  source              = "./modules/vpn"
  name                = "vpngw-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_subnet_id   = module.hub_network.subnet_ids["GatewaySubnet"]
}
