#
# vSphere Cluster
#
data "vsphere_datacenter" "dc" {
  name = var.vsphere_cluster.datacenter
}

data "vsphere_compute_cluster" "compute_cluster" {
  name = var.vsphere_cluster.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_resource_pool" "resource_pool" {
  name = var.vsphere_resource_pool
  parent_resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
}

data "vsphere_datastore" "datastore" {
  name = var.vsphere_cluster.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_storage_policy" "policy_home" {
  name = var.vsphere_cluster.policy_home
}

data "vsphere_storage_policy" "policy_os" {
  name = var.vsphere_cluster.policy_os
}

data "vsphere_storage_policy" "policy_data" {
  name = var.vsphere_cluster.policy_data
}

data "vsphere_distributed_virtual_switch" "dvs" {
  name = var.vsphere_cluster.dvs
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_1" {
  name = var.vsphere_cluster.portgroup
  datacenter_id = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}

data "vsphere_virtual_machine" "template" {
  name = var.vsphere_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

#
# Rally Nodes
#
resource "vsphere_virtual_machine" "rally_node_vm" {
  count = var.rally_node_count

  name = format("%s-%02d-%02d", var.rally_node_prefix, (var.vsphere_cluster_index + 1), (count.index + 1))
  resource_pool_id = vsphere_resource_pool.resource_pool.id
  datastore_id = data.vsphere_datastore.datastore.id
  storage_policy_id = data.vsphere_storage_policy.policy_home.id

  num_cpus = var.rally_node.cpu
  memory = var.rally_node.memory_gb * 1024
  guest_id = data.vsphere_virtual_machine.template.guest_id

  firmware = var.vsphere_vm_template_boot

  network_interface {
    network_id = data.vsphere_network.network_1.id
  }

  disk {
    label = format("%s-%02d-%02d-os-disk00", var.rally_node_prefix, (var.vsphere_cluster_index + 1), (count.index + 1))
    size = var.rally_node.os_disk_gb
    storage_policy_id = data.vsphere_storage_policy.policy_os.id
    unit_number = 0
  }

  hardware_version = 17

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = format("%s-%02d-%02d", var.rally_node_prefix, (var.vsphere_cluster_index + 1), (count.index + 1))
        domain = var.vsphere_cluster.dns_domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.ipv4_subnet, (var.vsphere_cluster.ipv4_start + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.ipv4_subnet)[0]
      }

      ipv4_gateway = var.vsphere_cluster.ipv4_gw
      dns_server_list = var.vsphere_cluster.dns_servers
      dns_suffix_list = var.vsphere_cluster.dns_suffix
    }
  }
}

#
# Elastic Nodes
#
resource "vsphere_virtual_machine" "es_node_vm" {
  count = var.es_node_count

  name = format("%s-%02d-%02d", var.es_node_prefix, (var.vsphere_cluster_index + 1), (count.index + 1))
  resource_pool_id = vsphere_resource_pool.resource_pool.id  
  datastore_id = data.vsphere_datastore.datastore.id
  storage_policy_id = data.vsphere_storage_policy.policy_home.id

  num_cpus = var.es_node.cpu
  memory = var.es_node.memory_gb * 1024
  guest_id = data.vsphere_virtual_machine.template.guest_id

  firmware = var.vsphere_vm_template_boot

  network_interface {
    network_id = data.vsphere_network.network_1.id
  }

  disk {
    label = format("%s-%02d-%02d-os-disk00", var.es_node_prefix, (var.vsphere_cluster_index + 1), (count.index + 1))
    size = var.es_node.os_disk_gb
    storage_policy_id = data.vsphere_storage_policy.policy_os.id
    unit_number = 0
  }

  dynamic "disk" {
    for_each = range(1, var.es_node.data_disk_count + 1)

    content {
      label = format("%s-%02d-%02d-data-disk%02d", var.es_node_prefix, (var.vsphere_cluster_index + 1), (count.index + 1), disk.value)
      size = var.es_node.data_disk_gb
      storage_policy_id = data.vsphere_storage_policy.policy_data.id
      unit_number = disk.value
    }
  }

  hardware_version = 17

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = format("%s-%02d-%02d", var.es_node_prefix, (var.vsphere_cluster_index + 1), (count.index + 1))
        domain = var.vsphere_cluster.dns_domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.ipv4_subnet, (var.vsphere_cluster.ipv4_start + var.rally_node_count + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.ipv4_subnet)[0]
      }

      ipv4_gateway = var.vsphere_cluster.ipv4_gw
      dns_server_list = var.vsphere_cluster.dns_servers
      dns_suffix_list = var.vsphere_cluster.dns_suffix
    }
  }
}

# Anti-affinity rules for es nodes
resource "vsphere_compute_cluster_vm_anti_affinity_rule" "es_node_anti_affinity_rule" {
  name                = "es-node-anti-affinity-rule"
  compute_cluster_id  = data.vsphere_compute_cluster.compute_cluster.id
  virtual_machine_ids = vsphere_virtual_machine.es_node_vm.*.id
}
