#
# Variables de definicion de Terraform.
#

#
# Variables definidas en el proyecto, como TF_VAR_xxx
# Se definen a nivel proyecto, por ser datos que no deben pode ser actualizados
# por usuarios normales.
#
variable "HYPERVISOR_USER" {
    description     = "Usuario para conectar al servidor vcenter"
    type            = string
    default         = "administrator@comunytek.com"
}

variable "HYPERVISOR_PASSWD" {
    description     = "Password del usuario para conectar al servidor vcenter"
    type            = string
    sensitive       = true
    default         = "Lagasca.67"
}

variable "HYPERVISOR_HOST" {
    description     = "Ip/hostname del servidor vcenter"
    type            = string
    default         = "vcenter.comunuyek.com"
}

#
# Resto de variables. Su valor se define en terraform.tfvars
#
variable "VM_NAME" {
    description     = "Nombre de la maquina virtual a crear/emplear"
    type            = string
}

variable "VM_DOMAIN" {
    description     = "Nombre de dominio de la maquina virtual a crear/emplear"
    type            = string
}

variable "VM_DATACENTER" {
    description     = "Nombre del Datacenter de vsphere"
    type            = string
}

variable "VM_DATASTORE" {
    description     = "Nombre del Datastore de vsphere"
    type            = string
}

variable "VM_RESOURCE_POOL" {
    description     = "Nombre del pool de recursos de vsphere"
    type            = string
}

variable "VM_NETWORK" {
    description     = "Nombre de la red de vsphere"
    type            = string
}

variable "VM_TEMPLATE_NAME" {
    description     = "Nombre de la plantilla a emplear"
    type            = string
}

variable "VM_NUM_CPUS" {
    description     = "Numero de hilos de CPU a reservar"
    type            = number
}

variable "VM_MEMORY_SIZE" {
    description     = "Tamaño en MB de memoria"
    type            = number
}

variable "VM_DISK_SIZE" {
    description     = "Tamaño en GB del disco duro"
    type            = number
}

