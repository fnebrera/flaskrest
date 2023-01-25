output "hyperv_instance_ip" {
    description     = "Ip publica de la maquina virtual creada"
    value           = vsphere_virtual_machine.test-cicd.default_ip_address
}

output "hyperv_host_name" {
    description     = "Hostname de la maquina virtual a crear"
    value           = var.VM_NAME
}
