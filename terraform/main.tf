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

  vsphere_cluster_index = count.index
  vsphere_cluster = var.vsphere_clusters[count.index]

  kafka_vm_prefix = var.kafka_vm_prefix
  kafka_broker = var.kafka_broker
  kafka_zookeeper = var.kafka_zookeeper
  kafka_connect = var.kafka_connect
  kafka_control_center = var.kafka_control_center
}

