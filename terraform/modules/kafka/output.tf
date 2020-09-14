output "rally_nodes" {
  value = {
    name = "cluster_${var.vsphere_cluster_index + 1}"
    hosts = vsphere_virtual_machine.rally_node_vm.*.default_ip_address
    hostnames = vsphere_virtual_machine.rally_node_vm.*.name
    domain = var.vsphere_cluster.dns_domain
  }
}

output "es_nodes" {
  value = {
    name = "cluster_${var.vsphere_cluster_index + 1}"
    hosts = vsphere_virtual_machine.es_node_vm.*.default_ip_address
    hostnames = vsphere_virtual_machine.es_node_vm.*.name
    domain = var.vsphere_cluster.dns_domain
  }
}
