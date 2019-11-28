variable "prefix" {
  description = "The Prefix used for all CycleCloud VM resources"
  default = "bewatrou-cc-tf"
}


variable "location" {
  description = "The Azure Region in which to run CycleCloud"
  default = "westus2"
}

variable "machine_type" {
  description = "The Azure Machine Type for the CycleCloud VM"
  default = "Standard_DS4_v2"
}

variable "cyclecloud_computer_name" {
    description =  "The private hostname for the CycleCloud VM"
    default = "cyclecloud"
}

variable "cyclecloud_dns_label" {
  description = "An optional short public DNS name/label for the CycleCloud VM"
}


variable "cyclecloud_username" {
  description = "The username for the initial CycleCloud Admin user and VM user"
  default = "ccadmin"
}

variable "cyclecloud_password" {
  description = "The initial password for the CycleCloud Admin user"
  default = "l3t3min!"
}


variable "cyclecloud_version" {
  description = "The version of the Azure CycleCloud image"
  default = "7.9.0"
}

# Storage account name can contain only lowercase letters and numbers.
variable "cyclecloud_storage_account" {
  description = "Name of storage account to use for Azure CycleCloud storage locker"
  default = "bewatroucctfstorage"
}

variable "cyclecloud_tenant_id" {
  description = "Service Principle Tenant ID"
}

variable "cyclecloud_application_id" {
  description = "Service Principle Application ID"
}

variable "cyclecloud_application_secret" {
  description = "Service Principle Application Secret"
}


