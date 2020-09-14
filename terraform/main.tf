provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_host" "cluster_1_hosts" {
  count         = length(var.vsphere_cluster_1_hosts)
  name          = var.vsphere_cluster_1_hosts[count.index]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "cluster_1_datastore" {
  name          = var.vsphere_cluster_1_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_distributed_virtual_switch" "cluster_1_dvs" {
  name          = var.vsphere_cluster_1_dvs
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "cluster_1_external_network" {
  name          = var.external_network
  datacenter_id = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.cluster_1_dvs.id
}

data "vsphere_network" "cluster_1_internal_network" {
  name          = var.internal_network
  datacenter_id = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.cluster_1_dvs.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "compute_cluster_1" {
  name            = var.vsphere_cluster_1
  datacenter_id   = data.vsphere_datacenter.dc.id
}

resource "vsphere_resource_pool" "resource_pool_1" {
  name                    = var.vsphere_resource_pool
  parent_resource_pool_id = data.vsphere_compute_cluster.compute_cluster_1.resource_pool_id
}

#
# Cluster 1
#
# Broker
resource "vsphere_virtual_machine" "cluster_1_broker" {
  count            = var.cluster_1_kafka_broker_count
  name             = format("cp-01-kafka-%02d", count.index + 1)
  resource_pool_id = vsphere_resource_pool.resource_pool_1.id
  datastore_id     = data.vsphere_datastore.cluster_1_datastore.id

  num_cpus = var.kafka_broker_cpu
  num_cores_per_socket =  var.kafka_broker_cpu / 2
  memory   = var.kafka_broker_ram
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = data.vsphere_network.cluster_1_external_network.id
  }

  network_interface {
    network_id = data.vsphere_network.cluster_1_internal_network.id
  }

  disk {
    label = format("kafka-%02d-os-disk0", count.index + 1)
    size  = var.kafka_broker_os_dir_size_gb
    unit_number = 0
  }

  # To add more Kafka Log disks, copy this disk block 
  # and update the unit number and label number
  disk {
    label = format("kafka-%02d-log-disk1", count.index + 1)
    size  = var.kafka_broker_data_dir_size_gb
    unit_number = 1
  }

  disk {
    label = format("kafka-%02d-log-disk2", count.index + 1)
    size  = var.kafka_broker_data_dir_size_gb
    unit_number = 2
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = format("cp-01-kafka-%02d", count.index + 1)
        domain    = var.dns_domain
      }

      network_interface {
        ipv4_address = var.cluster_1_kafka_broker_external_ips[count.index]
        ipv4_netmask = var.external_network_ipv4_netmask
      }

      network_interface {
        ipv4_address = var.cluster_1_kafka_broker_internal_ips[count.index]
        ipv4_netmask = var.internal_network_ipv4_netmask
      }

      ipv4_gateway = var.external_network_ipv4_gateway
      dns_server_list = var.dns_servers
      dns_suffix_list = var.dns_suffix_list
      
    }
  }
}

# Zookeeper
resource "vsphere_virtual_machine" "cluster_1_zookeeper" {
  count            = var.cluster_1_zookeeper_count
  name             = format("cp-01-zookeeper-%02d", count.index + 1)
  resource_pool_id = vsphere_resource_pool.resource_pool_1.id
  datastore_id     = data.vsphere_datastore.cluster_1_datastore.id


  num_cpus = var.zookeeper_cpu
  memory   = var.zookeeper_ram
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = data.vsphere_network.cluster_1_external_network.id
  }

  network_interface {
    network_id = data.vsphere_network.cluster_1_internal_network.id
  }

  disk {
    label = format("zookeeper-%02d-os-disk0", count.index + 1)
    size  = var.zookeeper_os_dir_size_gb
    unit_number = 0
  }

  disk {
    label = format("zookeeper-%02d-data-disk0", count.index + 1)
    size  = var.zookeeper_data_dir_size_gb
    unit_number = 1
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = format("cp-01-zookeeper-%02d", count.index + 1)
        domain    = var.dns_domain
      }
      
      network_interface {
        ipv4_address = var.cluster_1_zookeeper_external_ips[count.index]
        ipv4_netmask = var.external_network_ipv4_netmask
      }

      network_interface {
        ipv4_address = var.cluster_1_zookeeper_internal_ips[count.index]
        ipv4_netmask = var.internal_network_ipv4_netmask
      }

      ipv4_gateway = var.external_network_ipv4_gateway
      dns_server_list = var.dns_servers
      dns_suffix_list = var.dns_suffix_list
    }

  }
}

# Control Center
resource "vsphere_virtual_machine" "cluster_1_control_center" {
  count            = 1
  name             = "cp-01-controlcenter-01"
  resource_pool_id = vsphere_resource_pool.resource_pool_1.id
  datastore_id     = data.vsphere_datastore.cluster_1_datastore.id

  num_cpus = var.control_center_cpu
  memory   = var.control_center_ram
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = data.vsphere_network.cluster_1_external_network.id
  }

  disk {
    label = "os-disk0"
    size  = var.control_center_os_dir_size_gb
    unit_number = 0
  }

  disk {
    label = "data-disk0"
    size  = var.control_center_data_dir_size_gb
    unit_number = 1
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "cp-01-controlcenter-01"
        domain    = var.dns_domain
      }

      network_interface {
        ipv4_address = var.cluster_1_control_center_ip
        ipv4_netmask = var.external_network_ipv4_netmask
      }

      ipv4_gateway = var.external_network_ipv4_gateway
      dns_server_list = var.dns_servers
      dns_suffix_list = var.dns_suffix_list 
    }
  }
}

# Connect
resource "vsphere_virtual_machine" "cluster_1_kafka_connect" {
  count            = var.cluster_1_kafka_connect_count
  name             = format("cp-01-connect-%02d", count.index + 1)
  resource_pool_id = vsphere_resource_pool.resource_pool_1.id
  datastore_id     = data.vsphere_datastore.cluster_1_datastore.id

  num_cpus = var.kafka_connect_cpu
  num_cores_per_socket =  var.kafka_connect_cpu / 2
  memory   = var.kafka_connect_ram
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = data.vsphere_network.cluster_1_external_network.id
  }

  disk {
    label = "os-disk0"
    size  = var.kafka_connect_os_dir_size_gb
    unit_number = 0
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = format("cp-01-connect-%02d", count.index + 1)
        domain    = var.dns_domain
      }

      network_interface {
        ipv4_address = var.cluster_1_kafka_connect_ips[count.index]
        ipv4_netmask = var.external_network_ipv4_netmask
      }

      ipv4_gateway = var.external_network_ipv4_gateway
      dns_server_list = var.dns_servers
      dns_suffix_list = var.dns_suffix_list 
    }
  }
}

# Anti-afinity rules for Brokers and Zookeepers
resource "vsphere_compute_cluster_vm_anti_affinity_rule" "cluster_1_kafka_broker_anti_affinity_rule" {
  count               = var.cluster_1_kafka_broker_count > 0 ? 1 : 0
  name                = "kafka-broker-anti-affinity-rule"
  compute_cluster_id  = data.vsphere_compute_cluster.compute_cluster_1.id
  virtual_machine_ids = vsphere_virtual_machine.cluster_1_broker.*.id
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "cluster_1_zookeeper_anti_affinity_rule" {
  count               = var.cluster_1_zookeeper_count > 0 ? 1 : 0
  name                = "zookeeper-anti-affinity-rule"
  compute_cluster_id  = data.vsphere_compute_cluster.compute_cluster_1.id
  virtual_machine_ids = vsphere_virtual_machine.cluster_1_zookeeper.*.id
}

#
# Outputs
#
output "cluster_1_broker_public_ip" {
  value = vsphere_virtual_machine.cluster_1_broker.*.default_ip_address
}

output "cluster_1_zookeeper_public_ip" {
  value = vsphere_virtual_machine.cluster_1_zookeeper.*.default_ip_address
}

output "cluster_1_kafka_connect_public_ip" {
  value = vsphere_virtual_machine.cluster_1_kafka_connect.*.default_ip_address
}

output "control_center_public_ip" {
  value = vsphere_virtual_machine.cluster_1_control_center.*.default_ip_address
}

