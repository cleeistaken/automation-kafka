#
# vSphere Provider
#
provider "vsphere" {
  vsphere_server = var.vcenter_server
  user = var.vcenter_user
  password = var.vcenter_password
  allow_unverified_ssl = var.vcenter_insecure_ssl
}

module "kafka" {
  source = "./modules/kafka"

  count = length(var.vsphere_clusters)

  # Clusters
  vsphere_cluster_index = count.index
  vsphere_cluster = var.vsphere_clusters[count.index]

  # Prefix for all VM
  kafka_vm_prefix = var.kafka_vm_prefix

  # Broker
  kafka_broker_count_per_cluster = var.kafka_broker_count_per_cluster
  kafka_broker = var.kafka_broker

  # Zookeeper
  kafka_zookeeper_count_per_cluster = var.kafka_zookeeper_count_per_cluster
  kafka_zookeeper = var.kafka_zookeeper

  # Connect
  kafka_connect_count_per_cluster = var.kafka_connect_count_per_cluster
  kafka_connect = var.kafka_connect

  # Control center
  kafka_control_center = var.kafka_control_center
}

