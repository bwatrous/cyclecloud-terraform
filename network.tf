resource "azurerm_resource_group" "cc_tf_rg" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "cc_tf_vnet" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.cc_tf_rg.location
  resource_group_name = azurerm_resource_group.cc_tf_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "cc_tf_subnet" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.cc_tf_vnet.name
  resource_group_name  = azurerm_resource_group.cc_tf_rg.name
  address_prefix       = "10.0.0.0/24"
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_public_ip" "cc_tf_public_ip" {
  name                         = "${var.prefix}-public_ip"
  location                     = azurerm_resource_group.cc_tf_rg.location
  resource_group_name          = azurerm_resource_group.cc_tf_rg.name
  domain_name_label            = var.cyclecloud_dns_label
  allocation_method            = "Dynamic"
}

resource "azurerm_network_interface" "cc_tf_nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.cc_tf_rg.location
  resource_group_name = azurerm_resource_group.cc_tf_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cc_tf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cc_tf_public_ip.id
  }
}