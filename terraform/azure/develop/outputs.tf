output "hyperv_instance_ip" {
    description     = "Ip publica de la maquina virtual creada"
    value           = azurerm_public_ip.test-public-ip.ip_address
}

output "hyperv_host_name" {
    description     = "Hostname de la maquina virtual a crear"
    value           = var.VM_NAME
}
