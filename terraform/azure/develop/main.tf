############################################################################################################
# Terraform main file
############################################################################################################

#
# Recursos previamente creados
#

# El grupo de recursos lo hemos creado previamente desde el Panel
data "azurerm_resource_group" "test-cicd" {
  name     = "TEST-CICD"
}

# La red virtual la hemos creado al crear la VM semilla
data "azurerm_virtual_network" "test-cicd-vnet" {
  name                = "test-cicd-vnet"
  resource_group_name = data.azurerm_resource_group.test-cicd.name
}

#
# Recursos a crear
#

# Subnet a emplear en esta maquina virtual. Será diferente para uat y produccion
resource "azurerm_subnet" "test-cicd-subnet" {
  name                 = var.SUBNET_NAME
  address_prefixes     = [var.SUBNET_CIDR]
  resource_group_name  = data.azurerm_resource_group.test-cicd.name
  virtual_network_name = data.azurerm_virtual_network.test-cicd-vnet.name
}

# Nueva IP publica. La IP se asigna al crear la VM. Definida como Static para que no cambie al apagarla.
# Será diferente para uat y produccion
resource "azurerm_public_ip" "test-public-ip" {
  name                = var.PUBLIC_IP_NAME
  resource_group_name = data.azurerm_resource_group.test-cicd.name
  location            = data.azurerm_resource_group.test-cicd.location
  ip_version          = "IPv4"
  allocation_method   = "Static"
}

# Creamos un NIC para la nueva VM. Será diferente para uat y produccion
resource "azurerm_network_interface" "test-cicd-nic" {
  name                = var.NIC_NAME
  location            = data.azurerm_resource_group.test-cicd.location
  resource_group_name = data.azurerm_resource_group.test-cicd.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test-cicd-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test-public-ip.id
  }
}

#
# Maquina virtual, a partir de una imagen especializada
#
resource "azurerm_virtual_machine" "test-cicd" {
  name                = var.VM_NAME
  resource_group_name = data.azurerm_resource_group.test-cicd.name
  location            = data.azurerm_resource_group.test-cicd.location
  vm_size             = var.VM_SIZE

  network_interface_ids = [
    azurerm_network_interface.test-cicd-nic.id,
  ]

  storage_os_disk {
    name                 = "MainDisk"
    caching              = "ReadWrite"
    create_option        = "FromImage"
    disk_size_gb         = var.DISK_SIZE
  }

  delete_os_disk_on_termination = true

  storage_image_reference {
    id        = var.SEED_IMAGE
  }
}
