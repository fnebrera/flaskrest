#
# Variables de definicion de Terraform.
#

#
# Variables definidas en el proyecto, como TF_VAR_xxx
# Se definen a nivel proyecto, por ser datos que no deben poder ser actualizados
# por usuarios normales. Los default que ponemos aquí son solo para pruebas.
#
variable "HYPERVISOR_USER" {
    description     = "client_id del Service Principal de Azure"
    type            = string
    # Solo para pruebas. No se debe emplear en produccion
    default         = "d6619c91-e232-4372-ab6b-4bd101c5d965"
}

variable "HYPERVISOR_PASSWD" {
    description     = "Password del Service Principal de Azure"
    type            = string
    sensitive       = true
    default         = "3OS8Q~LM9oGMOCCVilyV2CxZhCWMegpxx4Tpdcdx"
}

variable "HYPERVISOR_HOST" {
    description     = "subscription_id del Service Principal de Azure"
    type            = string
    default         = "61726489-0dbf-4d0e-b5cd-2a6e330f64f9"
}

# Especifica de Azure. No se emplea en otras plataformas
variable "HYPERVISOR_TENANT" {
    description     = "tenant_id del Service Principal de Azure"
    type            = string
    default         = "b716c11f-16a3-4d15-8dbc-f11f7fdefe5a"
}

#
# Resto de variables. Su valor se define en terraform.tfvars
#
variable "VM_NAME" {
    description     = "Nombre de la maquina virtual a crear/emplear"
    type            = string
}

variable "VM_SIZE" {
    description     = "Tamaño de la maquina virtual a crear/emplear"
    type            = string
}

variable "DISK_SIZE" {
    description     = "Tamaño del disco a crear/emplear"
    type            = number
}

variable "SUBNET_NAME" {
    description     = "Nombre de la subnet a emplear"
    type            = string
}

variable "NIC_NAME" {
    description     = "Nombre de la interface de red a emplear"
    type            = string
}

variable "SUBNET_CIDR" {
    description     = "Definicion de la subnet a emplear"
    type            = string
}

variable "PUBLIC_IP_NAME" {
    description     = "Nombre de la IP publica a emplear"
    type            = string
}

variable "SEED_IMAGE" {
    description     = "Id de la imagen origen"
    type            = string
}
