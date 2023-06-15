locals {
  kafka_broker_disks = [
  for disk in range(0, var.broker_data_disk_count):
          "/mnt/kafka/data${disk}"
  ]
}

resource "local_file" "inventory" {
  content  = templatefile("${path.module}/inventory.yml.tpl", {

    # VMS
    vms_control_center = vsphere_virtual_machine.vms_control_center
    vms_kafka_broker = vsphere_virtual_machine.vms_kafka_broker
    vms_zookeeper = vsphere_virtual_machine.vms_zookeeper
    vms_kafka_connect = vsphere_virtual_machine.vms_kafka_connect

    broker_data_disks_count = var.broker_data_disk_count
    broker_data_disks = local.kafka_broker_disks

    # VM credentials
    vm_user = var.cloud_init_username
    vm_ssh_private_key_file = var.rsa_private_key_file

    # vCenter
    vcenter_server = var.vcenter_server
    vcenter_user = var.vcenter_user
    vcenter_password = var.vcenter_password
    vcenter_allow_unverified_ssl = var.vcenter_insecure_ssl

    # vSphere
    vsphere_datacenter = var.vsphere_datacenter
    vsphere_cluster = var.vsphere_compute_cluster

    # Automation System
    automation_system_local_ip = data.external.local_ip.result.ip
  })
  filename = "${var.output_folder}/inventory.yml"
  file_permission = "644"
}
