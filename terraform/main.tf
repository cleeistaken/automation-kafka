#
# vSphere Provider
#
provider "vsphere" {
  vsphere_server = var.vcenter_server
  user = var.vcenter_user
  password = var.vcenter_password
  allow_unverified_ssl = var.vcenter_insecure_ssl
}

#
# Get Local IP
#
data "external" "local_ip" {
  program = ["./get-ip.sh"]
}

#
# Content Library
#
module "template" {
  source = "./modules/template"

  # vSphere Cluster
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_datastore = var.vsphere_datastore

  # Template
  content_library_name = var.template_name
  content_library_item_url = format("http://%s/templates/%s", data.external.local_ip.result.ip, var.template_ova)
  content_library_item_name = var.template_name
  content_library_item_description = var.template_description
}

#
# Kafka VM
#
module "kafka" {
  source = "./modules/kafka"

  # vSphere
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_compute_cluster = var.vsphere_compute_cluster
  vsphere_folder_vm = var.vsphere_folder_vm
  vsphere_resource_pool = var.vsphere_resource_pool
  vsphere_network_1_portgroup = var.vsphere_network_1_portgroup
  vsphere_network_1_ipv4_subnet_cidr = var.vsphere_network_1_ipv4_subnet_cidr
  vsphere_network_1_ipv4_ips = var.vsphere_network_1_ipv4_ips
  vsphere_network_1_ipv4_gateway = var.vsphere_network_1_ipv4_gateway
  vsphere_network_2_portgroup = var.vsphere_network_1_portgroup
  vsphere_network_2_ipv4_subnet_cidr = var.vsphere_network_1_ipv4_subnet_cidr
  vsphere_network_2_ipv4_ips = var.vsphere_network_1_ipv4_ips
  vsphere_datastore = var.vsphere_datastore

  # Network
  network_domain_name = var.network_domain_name
  network_ipv4_dns_servers = var.network_ipv4_dns_servers
  network_dns_suffix = var.network_dns_suffix

  # Template
  template = module.template.content_library_item
  template_boot = var.template_boot

  # Prefix for all VM
  vm_kafka_prefix = var.vm_kafka_prefix

  # Control center
  vm_kafka_control_center = var.vm_kafka_control_center

  # Broker
  vm_kafka_broker_count_per_cluster = var.vm_kafka_broker_count_per_cluster
  vm_kafka_broker = var.vm_kafka_broker

  # Zookeeper
  vm_kafka_zookeeper_count_per_cluster = var.vm_kafka_zookeeper_count_per_cluster
  vm_kafka_zookeeper = var.vm_kafka_zookeeper

  # Connect
  vm_kafka_connect_count_per_cluster = var.vm_kafka_connect_count_per_cluster
  vm_kafka_connect = var.vm_kafka_connect
}
