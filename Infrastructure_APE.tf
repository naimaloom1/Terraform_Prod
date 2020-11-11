provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.0.0"
  features {}
  subscription_id = "81199c3c-1df1-4c7a-86ca-29892242b7cd"
}

# Create a resource group
resource "azurerm_resource_group" "Prod" {
  name     = "ResourceG_ADE_Prod"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "Prod" {
  name                = "vnet_APE"
  resource_group_name = "${azurerm_resource_group.Prod.name}"
  location            = "${azurerm_resource_group.Prod.location}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "Prod" {
  name                 = "subnet_APE"
  resource_group_name  = "${azurerm_resource_group.Prod.name}"
  virtual_network_name = "${azurerm_virtual_network.Prod.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "Prod" {
  name                = "ni_APE"
  location            = "${azurerm_resource_group.Prod.location}"
  resource_group_name = "${azurerm_resource_group.Prod.name}"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_subnet.Prod.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "Prod" {
  name                = "virtual_machine_APE"
  resource_group_name = "${azurerm_resource_group.Prod.name}"
  location            = "${azurerm_resource_group.Prod.location}"
  size                = "Standard_DS2_v2"
  admin_username      = "syed.2103015"
  admin_password      = "admin@123456"
  network_interface_ids = [
    azurerm_network_interface.Prod.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
resource "azurerm_storage_account" "Prod" {
  name                     = "Storage_APE"
  resource_group_name      = "${azurerm_resource_group.Prod.name}"
  location                 = "${azurerm_resource_group.Prod.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_sql_server" "Prod" {
  name                         = "Sqlserver_APE"
  resource_group_name          = "${azurerm_resource_group.Prod.name}"
  location                     = "${azurerm_resource_group.Prod.location}"
  version                      = "12.0"
  administrator_login          = "syed.2103015"
  administrator_login_password = "admin@123456"

  extended_auditing_policy {
    storage_endpoint                        = "azurerm_storage_account.Prod.primary_blob_endpoint"
    storage_account_access_key              = "azurerm_storage_account.Prod.primary_access_key"
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = {
    environment = "Prod"
  }
}