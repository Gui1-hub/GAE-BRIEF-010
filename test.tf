# Provider Azure
provider "azurerm" {
  features {}
  subscription_id = "09eef35c-bc62-40ab-8932-c171977b897b"
}

# Groupe de ressources
resource "azurerm_resource_group" "resource_group" {
  name     = "GAE-TEST-RG"
  location = "West Europe"
}

# Réseau virtuel
resource "azurerm_virtual_network" "virtual_network" {
  name                = "GAE-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Sous-réseau
resource "azurerm_subnet" "subnet" {
  name                 = "GAE-TEST-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# NSG (Groupe de sécurité réseau)
resource "azurerm_network_security_group" "nsg" {
  name                = "GAE-TEST-NSG"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Association explicite NSG <-> Sous-réseau
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Adresse IP publique
resource "azurerm_public_ip" "public_ip" {
  name                = "GAE-TEST-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
}

# Interface réseau
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

resource "azurerm_ssh_public_key" "test" {
  name                = "test"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  public_key          = file("/home/gui1/brief-10/id_rsa.pub")
}

# Machine virtuelle Ubuntu
resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                = "GAE-TEST-ubuntu-vm"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_B2s"
  admin_username      = "adminsimplon"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "adminsimplon"
    public_key = file("/home/gui1/brief-10/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.network_interface.id
  ]
}
