#
# Cluster
#
data "vsphere_datacenter" "vs_dc" {
  name = var.vsphere_cluster.vs_dc
}

data "vsphere_compute_cluster" "vs_cc" {
  name = var.vsphere_cluster.vs_cls
  datacenter_id = data.vsphere_datacenter.vs_dc.id
}

resource "vsphere_resource_pool" "vs_rp" {
  name = var.vsphere_cluster.vs_rp
  parent_resource_pool_id = data.vsphere_compute_cluster.vs_cc.resource_pool_id
}

data "vsphere_datastore" "vs_ds" {
  name = var.vsphere_cluster.vs_ds
  datacenter_id = data.vsphere_datacenter.vs_dc.id
}

data "vsphere_storage_policy" "vs_ds_policy" {
  name = var.vsphere_cluster.vs_ds_sp
}

data "vsphere_distributed_virtual_switch" "vs_dvs" {
  name = var.vsphere_cluster.vs_dvs
  datacenter_id = data.vsphere_datacenter.vs_dc.id
}

data "vsphere_network" "vs_dvs_pg_public" {
  name = var.vsphere_cluster.vs_dvs_pg_public
  datacenter_id = data.vsphere_datacenter.vs_dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.vs_dvs.id
}

data "vsphere_network" "vs_dvs_pg_private" {
  name = var.vsphere_cluster.vs_dvs_pg_private
  datacenter_id = data.vsphere_datacenter.vs_dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.vs_dvs.id
}

data "vsphere_virtual_machine" "vs_vm_template" {
  name = var.vsphere_cluster.vs_vm_template
  datacenter_id = data.vsphere_datacenter.vs_dc.id
}

#
# Control Center
#
locals {
  control_center_prefix = format("%s-control-center-%02d", var.kafka_vm_prefix, (var.vsphere_cluster_index + 1))
  control_center_ip_public_offset = var.vsphere_cluster.vs_dvs_pg_public_ipv4_start_hostnum
  control_center_ip_private_offset = var.vsphere_cluster.vs_dvs_pg_private_ipv4_start_hostnum
}

resource "vsphere_virtual_machine" "kafka_control_center" {
  count = 1
  name = format("%s-%02d", local.control_center_prefix, count.index + 1)

  # VM template
  guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.vsphere_cluster.vs_vm_template_boot

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vs_rp.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vs_ds.id
  storage_policy_id = data.vsphere_storage_policy.vs_ds_policy.id

  num_cpus = var.kafka_control_center.cpu
  memory   = var.kafka_control_center.memory_gb * 1024

  # vSphere automatically chooses the optimal so we should
  # not set this for *most* cases.
  # num_cores_per_socket =  var.kafka_broker_cpu / 2

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
  }

  disk {
    label = format("%s-%02d-os-disk0", local.control_center_prefix, count.index + 1)
    size  = var.kafka_control_center.data_disk_gb
    unit_number = 0
  }

  disk {
    label = format("%s-%02d-data-disk0", local.control_center_prefix, count.index + 1)
    size  = var.kafka_control_center.data_disk_gb
    unit_number = 1
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.vs_vm_template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.control_center_prefix, count.index + 1)
        domain    = var.vsphere_cluster.vs_vm_domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet, (local.control_center_ip_public_offset + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet)[0]
      }

      ipv4_gateway = var.vsphere_cluster.vs_dvs_pg_public_ipv4_gw
      dns_server_list = var.vsphere_cluster.vs_vm_dns
      dns_suffix_list = var.vsphere_cluster.vs_vm_dns_suffix
    }
  }
}

#
# Broker
#
locals {
  broker_prefix = format("%s-broker-%02d", var.kafka_vm_prefix, (var.vsphere_cluster_index + 1))
  broker_ip_public_offset = var.vsphere_cluster.vs_dvs_pg_public_ipv4_start_hostnum + 1
  broker_ip_private_offset = var.vsphere_cluster.vs_dvs_pg_private_ipv4_start_hostnum + 1
}

resource "vsphere_virtual_machine" "kafka_broker" {
  count = var.kafka_broker_count_per_cluster
  name = format("%s-%02d", local.broker_prefix, count.index + 1)

  # VM template
  guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.vsphere_cluster.vs_vm_template_boot

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vs_rp.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vs_ds.id
  storage_policy_id = data.vsphere_storage_policy.vs_ds_policy.id

  num_cpus = var.kafka_broker.cpu
  memory   = var.kafka_broker.memory_gb * 1024

  # vSphere automatically chooses the optimal so we should
  # not set this for *most* cases.
  # num_cores_per_socket =  var.kafka_broker_cpu / 2

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
  }

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_private.id
  }

  # Although it is possible to add multiple disk controllers, there is
  # no way as of v0.13 to assign a disk to a controller. All disks are
  # defaulted to the first controller.
  #scsi_controller_count = min (4, (var.kafka_broker.data_disk_count + 1))

  disk {
    label = format("%s-%02d-os-disk0", local.broker_prefix, count.index + 1)
    size  = var.kafka_broker.os_disk_gb
    unit_number = 0
  }

  dynamic "disk" {
    for_each = range(1, var.kafka_broker.data_disk_count + 1)

    content {
      label = format("%s-%02d-data-disk%02d", local.broker_prefix, (count.index + 1), disk.value)
      size = var.kafka_broker.data_disk_gb
      storage_policy_id = data.vsphere_storage_policy.vs_ds_policy.id
      unit_number = disk.value
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.vs_vm_template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.broker_prefix, count.index + 1)
        domain    = var.vsphere_cluster.vs_vm_domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet, (local.broker_ip_public_offset + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet)[0]
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.vs_dvs_pg_private_ipv4_subnet, (local.broker_ip_private_offset + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.vs_dvs_pg_private_ipv4_subnet)[0]
      }

      ipv4_gateway = var.vsphere_cluster.vs_dvs_pg_public_ipv4_gw
      dns_server_list = var.vsphere_cluster.vs_vm_dns
      dns_suffix_list = var.vsphere_cluster.vs_vm_dns_suffix

    }
  }
}

#
# Zookeeper
#
locals {
  zookeeper_prefix = format("%s-zookeeper-%02d", var.kafka_vm_prefix, (var.vsphere_cluster_index + 1))
  zookeeper_ip_public_offset = var.vsphere_cluster.vs_dvs_pg_public_ipv4_start_hostnum + 1 + var.kafka_broker_count_per_cluster
  zookeeper_ip_private_offset = var.vsphere_cluster.vs_dvs_pg_private_ipv4_start_hostnum + 1 + var.kafka_broker_count_per_cluster
}

resource "vsphere_virtual_machine" "kafka_zookeeper" {
  count = var.kafka_zookeeper_count_per_cluster
  name = format("%s-%02d", local.zookeeper_prefix, count.index + 1)

  # VM template
  guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.vsphere_cluster.vs_vm_template_boot

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vs_rp.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vs_ds.id
  storage_policy_id = data.vsphere_storage_policy.vs_ds_policy.id

  num_cpus = var.kafka_zookeeper.cpu
  memory   = var.kafka_zookeeper.memory_gb * 1024

  # vSphere automatically chooses the optimal so we should
  # not set this for *most* cases.
  # num_cores_per_socket =  var.kafka_broker_cpu / 2

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
  }

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_private.id
  }

  # Although it is possible to add multiple disk controllers, there is
  # no way as of v0.13 to assign a disk to a controller. All disks are
  # defaulted to the first controller.
  #scsi_controller_count = min (4, (var.kafka_zookeeper.data_disk_count + 1))

  disk {
    label = format("%s-%02d-os-disk0", local.zookeeper_prefix, count.index + 1)
    size  = var.kafka_zookeeper.data_disk_gb
    unit_number = 0
  }

  dynamic "disk" {
    for_each = range(1, var.kafka_zookeeper.data_disk_count + 1)

    content {
      label = format("%s-%02d-data-disk%02d", local.zookeeper_prefix, (count.index + 1), disk.value)
      size = var.kafka_zookeeper.data_disk_gb
      storage_policy_id = data.vsphere_storage_policy.vs_ds_policy.id
      unit_number = disk.value
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.vs_vm_template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.zookeeper_prefix, count.index + 1)
        domain    = var.vsphere_cluster.vs_vm_domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet, (local.zookeeper_ip_public_offset + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet)[0]
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.vs_dvs_pg_private_ipv4_subnet, (local.zookeeper_ip_private_offset + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.vs_dvs_pg_private_ipv4_subnet)[0]
      }

      ipv4_gateway = var.vsphere_cluster.vs_dvs_pg_public_ipv4_gw
      dns_server_list = var.vsphere_cluster.vs_vm_dns
      dns_suffix_list = var.vsphere_cluster.vs_vm_dns_suffix
    }
  }
}

#
# Connect
#
locals {
  connect_prefix = format("%s-connect-%02d", var.kafka_vm_prefix, (var.vsphere_cluster_index + 1))
  connect_ip_public_offset = var.vsphere_cluster.vs_dvs_pg_public_ipv4_start_hostnum + 1 + var.kafka_broker_count_per_cluster + var.kafka_zookeeper_count_per_cluster
  connect_ip_private_offset = var.vsphere_cluster.vs_dvs_pg_private_ipv4_start_hostnum + 1 + var.kafka_broker_count_per_cluster + var.kafka_zookeeper_count_per_cluster
}

resource "vsphere_virtual_machine" "kafka_connect" {
  count = var.kafka_connect_count_per_cluster
  name = format("%s-%02d", local.connect_prefix, count.index + 1)

  # VM template
  guest_id = data.vsphere_virtual_machine.vs_vm_template.guest_id

  # Template boot mode (efi or bios)
  firmware = var.vsphere_cluster.vs_vm_template_boot

  # Resource pool for created VM
  resource_pool_id = vsphere_resource_pool.vs_rp.id

  # Datastore and Storage Policy
  datastore_id     = data.vsphere_datastore.vs_ds.id
  storage_policy_id = data.vsphere_storage_policy.vs_ds_policy.id

  num_cpus = var.kafka_connect.cpu
  memory   = var.kafka_connect.memory_gb * 1024

  network_interface {
    network_id = data.vsphere_network.vs_dvs_pg_public.id
  }

  disk {
    label = format("%s-%02d-os-disk0", local.connect_prefix, count.index + 1)
    size  = var.kafka_zookeeper.data_disk_gb
    unit_number = 0
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.vs_vm_template.id

    customize {
      linux_options {
        host_name = format("%s-%02d", local.connect_prefix, count.index + 1)
        domain    = var.vsphere_cluster.vs_vm_domain
      }

      network_interface {
        ipv4_address = cidrhost(var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet, (local.connect_ip_public_offset + count.index))
        ipv4_netmask = regex("/([0-9]{1,2})$", var.vsphere_cluster.vs_dvs_pg_public_ipv4_subnet)[0]
      }

      ipv4_gateway = var.vsphere_cluster.vs_dvs_pg_public_ipv4_gw
      dns_server_list = var.vsphere_cluster.vs_vm_dns
      dns_suffix_list = var.vsphere_cluster.vs_vm_dns_suffix
    }
  }
}

# Anti-afinity rules for Brokers and Zookeepers
resource "vsphere_compute_cluster_vm_anti_affinity_rule" "kafka_broker_anti_affinity_rule" {
  count               = var.kafka_broker_count_per_cluster > 0 ? 1 : 0
  name                = "kafka-broker-anti-affinity-rule"
  compute_cluster_id  = data.vsphere_compute_cluster.vs_cc.id
  virtual_machine_ids = vsphere_virtual_machine.kafka_broker.*.id
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "zookeeper_anti_affinity_rule" {
  count               = var.kafka_zookeeper_count_per_cluster > 0 ? 1 : 0
  name                = "zookeeper-anti-affinity-rule"
  compute_cluster_id  = data.vsphere_compute_cluster.vs_cc.id
  virtual_machine_ids = vsphere_virtual_machine.kafka_zookeeper.*.id
}