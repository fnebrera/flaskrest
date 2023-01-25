#
# Objetos necesarios para el proyecto
#

# Datacenter
data "vsphere_datacenter" "datacenter" {
  name = var.VM_DATACENTER
}

# Datastore
data "vsphere_datastore" "datastore" {
  name          = var.VM_DATASTORE
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# SOLO SI HAY CLUSTER: data "vsphere_compute_cluster" "cluster" {
#  name          = "Cluster-1"
#  datacenter_id = data.vsphere_datacenter.datacenter.id
#}

data "vsphere_resource_pool" "pool" {
  name          = var.VM_RESOURCE_POOL
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.VM_NETWORK
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# Origen del clon
data "vsphere_virtual_machine" "plantilla" {
  name          = var.VM_TEMPLATE_NAME
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

#
# Definicion de recursos a crear/destruir
#
resource "vsphere_virtual_machine" "test-cicd" {
  name             = var.VM_NAME
  # SOLO SI HAY CLUSTER: resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.VM_NUM_CPUS
  memory           = var.VM_MEMORY_SIZE
  guest_id         = data.vsphere_virtual_machine.plantilla.guest_id
  scsi_type        = data.vsphere_virtual_machine.plantilla.scsi_type
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = var.VM_DISK_SIZE
    thin_provisioned = true
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.plantilla.id
    customize {
      linux_options {
        host_name = var.VM_NAME
        domain    = var.VM_DOMAIN
      }
      # Usar DHCP
      network_interface {}
    }
  }
}
