output "kafka_env" {
  value = {
    "cluster_id" = var.vsphere_cluster_index + 1
    "cluster" = {
      "broker" = vsphere_virtual_machine.kafka_broker
      "control_center" = vsphere_virtual_machine.kafka_control_center
      "connect" = vsphere_virtual_machine.kafka_connect
      "zookeeper" = vsphere_virtual_machine.kafka_zookeeper
    }
  }
}