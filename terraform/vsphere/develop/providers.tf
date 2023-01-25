# El estado se mantiene en remoto mediante http
terraform {
  backend "http" {
  }
}

# Servidor vcenter sobre el que vamos a crear la maquina virtual 
provider "vsphere" {
  user            = var.HYPERVISOR_USER
  password        = var.HYPERVISOR_PASSWD
  vsphere_server  = var.HYPERVISOR_HOST
  allow_unverified_ssl = true
}
