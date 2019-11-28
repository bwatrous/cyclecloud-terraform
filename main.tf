locals {
  virtual_machine_name = "${var.prefix}-vm"
}

provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.36.0"
}

resource "azurerm_storage_account" "cc_tf_locker" {
  name                     = var.cyclecloud_storage_account
  resource_group_name      = azurerm_resource_group.cc_tf_rg.name
  location                 = azurerm_resource_group.cc_tf_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


resource "azurerm_virtual_machine" "cc_tf_vm" {
  name                  = local.virtual_machine_name
  resource_group_name   = azurerm_resource_group.cc_tf_rg.name
  location              = azurerm_resource_group.cc_tf_rg.location
  network_interface_ids = [azurerm_network_interface.cc_tf_nic.id]
  vm_size               = var.machine_type

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.6"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.virtual_machine_name}-osdisk"
    disk_size_gb      = "128"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.cyclecloud_computer_name
    admin_username = var.cyclecloud_username
    admin_password = var.cyclecloud_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
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
  #name                 = random_uuid.cc_tf_mi_role_id.result
  scope                = data.azurerm_subscription.current.id
  #role_definition_name = "Contributor"
  role_definition_id   = data.azurerm_role_definition.contributor.id
  principal_id         = lookup(azurerm_virtual_machine.cc_tf_vm.identity[0], "principal_id")
}

resource "azurerm_virtual_machine_extension" "initial_custom_script" {
  name                 = "CustomScriptExtension"
  location             = azurerm_resource_group.cc_tf_rg.location
  resource_group_name  = azurerm_resource_group.cc_tf_rg.name
  virtual_machine_name = azurerm_virtual_machine.cc_tf_vm.name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = [azurerm_virtual_machine.cc_tf_vm]

  settings = <<SETTINGS
    {
        "commandToExecute": "echo \"Launch Time: \" > /tmp/launch_time  && date >> /tmp/launch_time"
    }
SETTINGS
}


resource "azurerm_virtual_machine_extension" "fetch_cyclecloud_install_script" {
  name                 = "CustomScriptExtension"
  location             = azurerm_resource_group.cc_tf_rg.location
  resource_group_name  = azurerm_resource_group.cc_tf_rg.name
  virtual_machine_name = azurerm_virtual_machine.cc_tf_vm.name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on = [azurerm_virtual_machine_extension.initial_custom_script]

  settings = <<SETTINGS
    {
        "commandToExecute": "curl -k -L -o /tmp/install_cyclecloud.py \"https://raw.githubusercontent.com/bwatrous/cyclecloud-terraform/master/scripts/cyclecloud_install.py\""
    }
SETTINGS
}


resource "azurerm_virtual_machine_extension" "install_cyclecloud" {
  name                 = "CustomScriptExtension"
  location             = azurerm_resource_group.cc_tf_rg.location
  resource_group_name  = azurerm_resource_group.cc_tf_rg.name
  virtual_machine_name = azurerm_virtual_machine.cc_tf_vm.name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on = [azurerm_virtual_machine_extension.fetch_cyclecloud_install_script]

#   settings = <<SETTINGS
#     {
#         "commandToExecute": "python /tmp/install_cyclecloud.py --acceptTerms --tenantId=${var.cyclecloud_tenant_id} \
#             --applicationId=${var.cyclecloud_application_id} --applicationSecret=${var.cyclecloud_application_secret} \
#             --username=${var.cyclecloud_username} --password=${var.cyclecloud_password} \
#             --storageAccount=${var.cyclecloud_storage_account} --hostname=${var.cyclecloud_dns_label}"
#     }
# SETTINGS
    # ${var.cyclecloud_dns_label}.${var.location}.cloudapp.azure.com" 
  settings = <<SETTINGS
    {
        "commandToExecute": "python /tmp/install_cyclecloud.py --acceptTerms --useManagedIdentity --username=${var.cyclecloud_username} --password='${var.cyclecloud_password}' --storageAccount=${var.cyclecloud_storage_account} --hostname=${azurerm_public_ip.cc_tf_public_ip.fqdn}"
    }
SETTINGS
}