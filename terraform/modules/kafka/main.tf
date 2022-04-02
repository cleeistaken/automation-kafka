#
# Cluster
#
data "vsphere_datacenter" "vsphere_datacenter_1" {
  name = var.vsphere_datacenter
}

resource "vsphere_folder" "vsphere_folder_1" {
  path          = var.vsphere_folder_vm
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter_1.id
}

data "vsphere_compute_cluster" "vsphere_compute_cluster_1" {
  name = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter_1.id
}

resource "vsphere_resource_pool" "vsphere_resource_pool_1" {
  name = var.vsphere_resource_pool
  parent_resource_pool_id = data.vsphere_compute_cluster.vsphere_compute_cluster_1.resource_pool_id
}

data "vsphere_datastore" "vsphere_datastore_1" {
  name = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter_1.id
}

data "vsphere_network" "vs_dvs_pg_public" {
  name = var.vsphere_network_1_ipv4_subnet_cidr
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter_1.id
}

data "vsphere_network" "vs_dvs_pg_private" {
  name = var.vsphere_network_2_ipv4_subnet_cidr
  datacenter_id = data.vsphere_datacenter.vsphere_datacenter_1.id
}

variable "ovf_map" {
  type    = list(string)
  default = ["eth0", "eth1", "eth2", "eth3"]
}

# Locals
locals {
  # Control Center
  control_center_prefix = format("%s-control-center", var.vm_kafka_prefix)
  control_center_public_ip_offset = 0
  control_center_private_ip_offset = 0

  # Broker
  broker_prefix = format("%s-broker", var.vm_kafka_prefix)
  broker_public_ip_offset = 1
  broker_private_ip_offset = 0

  # Zookeeper
  zookeeper_vm_prefix = format("%s-zookeeper", var.vm_kafka_prefix)
  zookeeper_public_ip_offset = 1 + var.vm_kafka_broker_count_per_cluster
  zookeeper_private_ip_offset = var.vm_kafka_broker_count_per_cluster

  # Connect
  connect_vm_prefix = format("%s-connect", var.vm_kafka_prefix)
  connect_public_ip_offset = 1 + var.vm_kafka_broker_count_per_cluster + var.vm_kafka_zookeeper_count_per_cluster
  connect_private_ip_offset = var.vm_kafka_broker_count_per_cluster + var.vm_kafka_zookeeper_count_per_cluster
}

#
# Control Center
#
resource "vsphere_virtual_machine" "kafka_control_center" {
  count = 1
  name = format("%s-%02d", local.control_center_prefix, count.index + 1)

  # VM template
  #guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.template_boot

  # VM Folder
  folder = vsphere_folder.vsphere_folder_1.path

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vsphere_resource_pool_1.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vsphere_datastore_1.id

  num_cpus = var.vm_kafka_control_center.cpu
  memory   = var.vm_kafka_control_center.memory_gb * 1024

  # vSphere automatically chooses the optimal so we should
  # not set this for *most* cases.
  # num_cores_per_socket =  var.kafka_broker_cpu / 2

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
    ovf_mapping = var.ovf_map[0]
  }

  scsi_controller_count = 1

  disk {
    label = format("%s-%02d-os-disk0", local.control_center_prefix, count.index + 1)
    size  = var.vm_kafka_control_center.data_disk_gb
    unit_number = 0
  }

  disk {
    label = format("%s-%02d-data-disk0", local.control_center_prefix, count.index + 1)
    size  = var.vm_kafka_control_center.data_disk_gb
    unit_number = 1
  }

  clone {
    template_uuid = var.template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.control_center_prefix, count.index + 1)
        domain    = var.network_domain_name
      }

      network_interface {
        ipv4_address = var.vsphere_network_1_ipv4_ips[local.control_center_public_ip_offset]
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_network_1_ipv4_subnet_cidr)[0]
      }

      ipv4_gateway = var.vsphere_network_1_ipv4_gateway
      dns_server_list = var.network_ipv4_dns_servers
      dns_suffix_list = var.network_dns_suffix
    }
  }
}

#
# Broker
#
resource "vsphere_virtual_machine" "kafka_broker" {
  count = var.vm_kafka_broker_count_per_cluster
  name = format("%s-%02d", local.broker_prefix, count.index + 1)

  # VM template
  #guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.template_boot

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vsphere_resource_pool_1.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vsphere_datastore_1.id

  num_cpus = var.vm_kafka_broker.cpu
  memory   = var.vm_kafka_broker.memory_gb * 1024

  # vSphere automatically chooses the optimal so we should
  # not set this for *most* cases.
  # num_cores_per_socket =  var.kafka_broker_cpu / 2

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
    ovf_mapping    = var.ovf_map[0]
  }

  dynamic "network_interface" {
    for_each = range(1, 2)
    content {
      network_id = data.vsphere_network.vs_dvs_pg_private.id
      ovf_mapping = var.ovf_map[network_interface.value]
    }
  }

  scsi_controller_count = max(1, min(4, var.vm_kafka_broker.data_disk_count + 1))

  disk {
    label = format("%s-%02d-os-disk0", local.broker_prefix, count.index + 1)
    size  = var.vm_kafka_broker.os_disk_gb
    unit_number = 0
  }

  # scsi0:0-14 are unit numbers 0-14
  # scsi1:0-14 are unit numbers 15-29
  # scsi2:0-14 are unit numbers 30-44
  # scsi3:0-14 are unit numbers 45-59
  dynamic "disk" {
    for_each = range(0, var.vm_kafka_broker.data_disk_count)

    content {
      label             = format("%s-%02d-data-disk%d", local.broker_prefix, (count.index + 1), (disk.value + 1))
      size              = var.vm_kafka_broker.data_disk_gb
      unit_number       = 15 + ((disk.value % 3) * 14) + disk.value
    }
  }

  clone {
    template_uuid = var.template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.broker_prefix, count.index + 1)
        domain    = var.network_domain_name
      }

      network_interface {
        ipv4_address = var.vsphere_network_1_ipv4_ips[local.broker_public_ip_offset + count.index]
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_network_1_ipv4_subnet_cidr)[0]
      }

      network_interface {
        ipv4_address = var.vsphere_network_2_ipv4_ips[local.broker_private_ip_offset + count.index]
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_network_2_ipv4_subnet_cidr)[0]
      }

      ipv4_gateway = var.vsphere_network_1_ipv4_gateway
      dns_server_list = var.network_ipv4_dns_servers
      dns_suffix_list = var.network_dns_suffix

    }
  }
}

#
# Zookeeper
#
resource "vsphere_virtual_machine" "kafka_zookeeper" {
  count = var.vm_kafka_zookeeper_count_per_cluster
  name = format("%s-%02d", local.zookeeper_vm_prefix, count.index + 1)

  # VM template
  #guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.template_boot

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vsphere_resource_pool_1.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vsphere_datastore_1.id

  num_cpus = var.vm_kafka_zookeeper.cpu
  memory   = var.vm_kafka_zookeeper.memory_gb * 1024

  # vSphere automatically chooses the optimal so we should
  # not set this for *most* cases.
  # num_cores_per_socket =  var.kafka_broker_cpu / 2

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
    ovf_mapping    = var.ovf_map[0]
  }

  dynamic "network_interface" {
    for_each = range(1, 2)
    content {
      network_id = data.vsphere_network.vs_dvs_pg_private.id
      ovf_mapping = var.ovf_map[network_interface.value]
    }
  }

  scsi_controller_count = max(1, min(4, var.vm_kafka_zookeeper.data_disk_count + 1))

  disk {
    label = format("%s-%02d-os-disk0", local.zookeeper_vm_prefix, count.index + 1)
    size  = var.vm_kafka_zookeeper.os_disk_gb
    unit_number = 0
  }

  # scsi0:0-14 are unit numbers 0-14
  # scsi1:0-14 are unit numbers 15-29
  # scsi2:0-14 are unit numbers 30-44
  # scsi3:0-14 are unit numbers 45-59
  dynamic "disk" {
    for_each = range(0, var.vm_kafka_zookeeper.data_disk_count)

    content {
      label             = format("%s-%02d-data-disk%d", local.zookeeper_vm_prefix, (count.index + 1), (disk.value + 1))
      size              = var.vm_kafka_zookeeper.data_disk_gb
      unit_number       = 15 + ((disk.value % 3) * 14) + disk.value
    }
  }

  clone {
    template_uuid = var.template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.zookeeper_vm_prefix, count.index + 1)
        domain    = var.network_domain_name
      }

      network_interface {
        ipv4_address = var.vsphere_network_1_ipv4_ips[local.zookeeper_public_ip_offset + count.index]
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_network_1_ipv4_subnet_cidr)[0]
      }

      network_interface {
        ipv4_address = var.vsphere_network_2_ipv4_ips[local.zookeeper_private_ip_offset + count.index]
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_network_2_ipv4_subnet_cidr)[0]
      }

      ipv4_gateway = var.vsphere_network_1_ipv4_gateway
      dns_server_list = var.network_ipv4_dns_servers
      dns_suffix_list = var.network_dns_suffix
    }
  }
}

#
# Connect
#
resource "vsphere_virtual_machine" "kafka_connect" {
  count = var.vm_kafka_connect_count_per_cluster
  name = format("%s-%02d", local.connect_vm_prefix, count.index + 1)

  # VM template
  #guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.template_boot

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vsphere_resource_pool_1.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vsphere_datastore_1.id

  num_cpus = var.vm_kafka_connect.cpu
  memory   = var.vm_kafka_connect.memory_gb * 1024

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
    ovf_mapping    = var.ovf_map[0]
  }

  disk {
    label = format("%s-%02d-os-disk0", local.connect_vm_prefix, count.index + 1)
    size  = var.vm_kafka_connect.os_disk_gb
    unit_number = 0
  }

  clone {
    template_uuid = var.template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.connect_vm_prefix, count.index + 1)
        domain    = var.network_domain_name
      }

      network_interface {
        ipv4_address = var.vsphere_network_1_ipv4_ips[local.connect_public_ip_offset + count.index]
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_network_1_ipv4_subnet_cidr)[0]
      }

      ipv4_gateway = var.vsphere_network_1_ipv4_gateway
      dns_server_list = var.network_ipv4_dns_servers
      dns_suffix_list = var.network_dns_suffix
    }
  }
}

# Anti-affinity rules for Brokers and Zookeepers
resource "vsphere_compute_cluster_vm_anti_affinity_rule" "kafka_broker_anti_affinity_rule" {
  count               = var.vm_kafka_broker_count_per_cluster > 0 ? 1 : 0
  name                = "kafka-broker-anti-affinity-rule"
  compute_cluster_id  = data.vsphere_compute_cluster.vsphere_compute_cluster_1.id
  virtual_machine_ids = vsphere_virtual_machine.kafka_broker.*.id
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "zookeeper_anti_affinity_rule" {
  count               = var.vm_kafka_zookeeper_count_per_cluster > 0 ? 1 : 0
  name                = "zookeeper-anti-affinity-rule"
  compute_cluster_id  = data.vsphere_compute_cluster.vsphere_compute_cluster_1.id
  virtual_machine_ids = vsphere_virtual_machine.kafka_zookeeper.*.id
}