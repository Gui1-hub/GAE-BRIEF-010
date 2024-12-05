provider "azurerm" {
  features {}
  subscription_id = "09eef35c-bc62-40ab-8932-c171977b897b"
}
# Définir le groupe de ressources
resource "azurerm_resource_group" "resource_group" {
  name     = "GAE-TEST-RG"
  location = "FranceCentral"
}

# Définir le réseau virtuel
resource "azurerm_virtual_network" "virtual_network" {
  name                = "GAE-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Définir le sous-réseau
resource "azurerm_subnet" "subnet" {
  name                 = "GAE-TEST-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Définir l'adresse IP publique
resource "azurerm_public_ip" "public_ip" {
  name                = "GAE-TEST-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Dynamic"
}

# Définir l'interface réseau
resource "azurerm_network_interface" "network_interface" {
  name                = "GAE-TEST-NIC"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Créer la machine virtuelle Ubuntu
resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                = "GAE-TEST-ubuntu-vm"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_B2ms"
  admin_username      = "adminsimplon"
  admin_password      = "P@ssw0rd123!"
  network_interface_ids = [
    azurerm_network_interface.network_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }
}
