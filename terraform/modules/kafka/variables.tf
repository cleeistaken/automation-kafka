#
# vSphere
#
variable vsphere_vm_template {
  type = string
}

variable vsphere_vm_template_boot {
  type = string
}

variable vsphere_cluster_index {
  type = number
  default = 0
}

variable vsphere_resource_pool {
  type = string
  default = "elastic"
}

variable vsphere_cluster {
  type = object({
    datacenter = string
    cluster = string
    dvs = string
    portgroup = string
    ipv4_subnet = string
    ipv4_start = number
    ipv4_gw = string
    dns_domain = string
    dns_servers = list(string)
    dns_suffix = list(string)
    datastore = string
    policy_home = string
    policy_os = string
    policy_data = string
  })
}

#
# Rally Nodes
#

variable rally_node_prefix {
  type = string
  default = "rally-node"
}

variable rally_node_count {
  type = number
}

variable rally_node {
  type = object({
    cpu = number
    memory_gb = number
    os_disk_gb = number
  })
}

#
# Elastic Nodes
#
variable es_node_prefix {
  type = string
  default = "es-node"
}

variable es_node_count {
  type = number
}

variable es_node {
  type = object({
    cpu = number
    memory_gb = number
    os_disk_gb = number
    data_disk_count = number
    data_disk_gb = number
  })
}
