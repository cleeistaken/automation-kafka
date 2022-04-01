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
  vsphere_cluster = var.vsphere_cluster

  # Template
  content_library_item_url = format("http://%s/%s", data.external.local_ip.result.ip, var.template_ova)
  content_library_item_name = var.template_name
  content_library_item_description = var.template_description
}

#
# Kafka VM
#
module "kafka" {
  source = "./modules/kafka"

  # Clusters
  vsphere_cluster = var.vsphere_cluster

  # Template
  template = module.template.content_library_item
  template_boot = var.template_boot

  # Prefix for all VM
  kafka_vm_prefix = var.kafka_vm_prefix

  # Control center
  kafka_control_center = var.kafka_control_center

  # Broker
  kafka_broker_count_per_cluster = var.kafka_broker_count_per_cluster
  kafka_broker = var.kafka_broker

  # Zookeeper
  kafka_zookeeper_count_per_cluster = var.kafka_zookeeper_count_per_cluster
  kafka_zookeeper = var.kafka_zookeeper

  # Connect
  kafka_connect_count_per_cluster = var.kafka_connect_count_per_cluster
  kafka_connect = var.kafka_connect
}
