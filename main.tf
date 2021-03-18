locals {
  virtual_machine_name = "${var.prefix}-vm"
  cyclecloud_install_script_url = "https://raw.githubusercontent.com/bwatrous/cyclecloud-terraform/feature/update_install_script/scripts/cyclecloud_install.py"
}

provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.16"
  features {}
}

resource "azurerm_storage_account" "cc_tf_locker" {
  name                     = var.cyclecloud_storage_account
  resource_group_name      = azurerm_resource_group.cc_tf_rg.name
  location                 = azurerm_resource_group.cc_tf_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


resource "azurerm_linux_virtual_machine" "cc_tf_vm" {
  name                  = local.virtual_machine_name
  resource_group_name   = azurerm_resource_group.cc_tf_rg.name
  location              = azurerm_resource_group.cc_tf_rg.location
  network_interface_ids = [azurerm_network_interface.cc_tf_nic.id]
  size                  = var.machine_type

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS-HPC"
    sku       = "8_1"
    version   = "latest"
  }

  os_disk {
    name              = "${local.virtual_machine_name}-osdisk"
    disk_size_gb      = var.os_disk_size_gb
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username      = var.cyclecloud_username
  admin_ssh_key {
    username   = var.cyclecloud_username
    public_key = var.cyclecloud_user_publickey
  }

}

data "azurerm_subscription" "current" {}

# Retrieve the contributor role, scoped to our subscription
#data "azurerm_builtin_role_definition" "contributor" {
#  name = "Contributor"
#}
data "azurerm_role_definition" "contributor" {
    name  = "Contributor"
    scope = "${data.azurerm_subscription.current.id}"
}

resource "random_uuid" "cc_tf_mi_role_id" { }

resource "azurerm_role_assignment" "cc_tf_mi_role" {
  scope                = data.azurerm_subscription.current.id
  role_definition_id   = data.azurerm_role_definition.contributor.id
  principal_id         = lookup(azurerm_linux_virtual_machine.cc_tf_vm.identity[0], "principal_id")
}

resource "azurerm_virtual_machine_extension" "install_cyclecloud" {
  name                 = "CustomScriptExtension"
  virtual_machine_id   = azurerm_linux_virtual_machine.cc_tf_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = [azurerm_linux_virtual_machine.cc_tf_vm]

    # ${var.cyclecloud_dns_label}.${var.location}.cloudapp.azure.com" 
  settings = <<SETTINGS
    {
        "commandToExecute": "echo \"Launch Time: \" > /tmp/launch_time  && date >> /tmp/launch_time && curl -k -L -o /tmp/cyclecloud_install.py \"${local.cyclecloud_install_script_url}\" && python3 /tmp/cyclecloud_install.py --acceptTerms --useManagedIdentity --username=${var.cyclecloud_username} --password='${var.cyclecloud_password}' --publickey='${var.cyclecloud_user_publickey}' --storageAccount=${var.cyclecloud_storage_account} --webServerMaxHeapSize=4096M --webServerPort=80 --webServerSslPort=443"
    }
SETTINGS
}
