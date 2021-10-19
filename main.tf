provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
    name     = "${var.prefix}-rg"
    location = var.location

    tags = {
        enviroment  = var.tag
    }
}

resource "azurerm_virtual_network" "main" {
    name                = "${var.prefix}-net"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    tags = {
        enviroment  = var.tag
    }
}

resource "azurerm_subnet" "internal" {
    name                 = "internal"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "main" {
    name = "${var.prefix}-nsg"
    location  = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    security_rule {
        name = "AllowVirtualNetworkInBound"
        priority = 101
        direction  = "Inbound"
        access = "Allow"
        protocol = "*"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix= "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name = "DenyInternetInBound"
        priority = 100
        direction = "Inbound"
        access = "Deny"
        protocol = "*"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = "Internet"
        destination_address_prefix = "VirtualNetwork"
    }

    tags = {
        enviroment  = var.tag
    }
}

resource "azurerm_network_interface" "main" {
    count = var.count_of_vm

    name                = "${var.prefix}-nic-${var.server_names[count.index]}"
    resource_group_name = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
    }
    tags = {
        enviroment  = var.tag
    }
}

resource "azurerm_public_ip" "main" {
    name = "${var.prefix}-public-ip"
    resource_group_name = azurerm_resource_group.main.name
    location = azurerm_resource_group.main.location
    allocation_method = "Static"

    tags = {
        enviroment  = var.tag
    }
}


resource "azurerm_lb" "main" {
    name  = "${var.prefix}-lb"
    location = "${var.location}"
    resource_group_name = azurerm_resource_group.main.name

    frontend_ip_configuration {
        name  = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.main.id
    }

    tags = {
        enviroment  = var.tag
    }
}

resource "azurerm_lb_backend_address_pool" "main" {
    resource_group_name = azurerm_resource_group.main.name
    loadbalancer_id = azurerm_lb.main.id
    name = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
    count = var.count_of_vm

    network_interface_id    = azurerm_network_interface.main[count.index].id
    ip_configuration_name   = "internal"
    backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_availability_set" "main" {
    name = "${var.prefix}-aset"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
       
    tags = {
        enviroment  = var.tag
    }
}

data "azurerm_resource_group" "main" {
    name = var.packer_resource_group_name
}

data "azurerm_image" "main" {
    name = var.packer_image_name
    resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_virtual_machine" "myVM2" {
    count = var.count_of_vm

    name                             = "${var.prefix}-vm-${var.server_names[count.index]}"
    location                         = azurerm_resource_group.main.location
    resource_group_name              = azurerm_resource_group.main.name
    vm_size                          = "Standard_D2s_v3"

    network_interface_ids = [azurerm_network_interface.main[count.index].id]
    availability_set_id = azurerm_availability_set.main.id


    storage_image_reference {
        id = "${data.azurerm_image.main.id}"
    }

    storage_os_disk {
        name              = "myVM2-OS-${var.server_names[count.index]}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "APPVM"
        admin_username = "devopsadmin"
        admin_password = "Cssladmin#2019"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = var.tag
        name = "${var.server_names[count.index]}-VM"
    }
}