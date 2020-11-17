variable vsphere_cluster_index {
  type = number
  default = 0
}

variable vsphere_cluster {
  type = object({
    # vSphere Datacenter
    vs_dc = string

    # vSphere Cluster in the Datacenter
    vs_cls = string

    # vSphere Resource Pool
    vs_rp = string

    # vSphere Distributed Virtual Switch
    vs_dvs = string

    # vSphere Distributed Portgroup for the public/routed network
    vs_dvs_pg_public = string

    # Public Portgroup IPv4 subnet in CIDR notation (e.g. 10.0.0.0/24)
    vs_dvs_pg_public_ipv4_subnet = string

    # Public Portgroup IPv4 addresses
    vs_dvs_pg_public_ipv4_ips = list(string)

    # Public Portgroup IPv4 gateway address
    vs_dvs_pg_public_ipv4_gw = string

    # vSphere Distributed Portgroup for the private network
    vs_dvs_pg_private = string

    # Private Portgroup IPv4 subnet in CIDR notation (e.g. 10.0.0.0/24)
    vs_dvs_pg_private_ipv4_subnet = string

    # Private Portgroup IPv4 addresses
    vs_dvs_pg_private_ipv4_ips = list(string)

    # vSphere vSAN datastore
    vs_ds = string

    # vSphere vSAN Storage Policy
    vs_ds_sp = string

    # Virtual Machine template to clone from
    vs_vm_template = string

    # Virtual Machine template boot mode (bios/efi)
    vs_vm_template_boot = string

    # Virtual machine domain name
    vs_vm_domain = string

    # Virtual Machine DNS servers
    vs_vm_dns = list(string)

    # Virtual Machine DNS suffixes
    vs_vm_dns_suffix = list(string)
  })
}

variable kafka_broker_count_per_cluster {
  type = number
  default = 4
}

variable kafka_zookeeper_count_per_cluster {
  type = number
  default = 3
}

variable kafka_connect_count_per_cluster {
  type = number
  default = 3
}

variable kafka_vm_prefix {
  type = string
  default = "kafka"
}

variable kafka_broker {
  type = object({
    cpu = number
    memory_gb = number
    os_disk_gb = number
    data_disk_count = number
    data_disk_gb = number
  })
}

variable kafka_zookeeper {
  type = object({
    cpu = number
    memory_gb = number
    os_disk_gb = number
    data_disk_count = number
    data_disk_gb = number
  })
}

variable kafka_connect {
  type = object({
    cpu = number
    memory_gb = number
    os_disk_gb = number
  })
}

variable kafka_control_center {
  type = object({
    cpu = number
    memory_gb = number
    os_disk_gb = number
    data_disk_gb = number
  })
}
