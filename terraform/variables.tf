#
# vCenter
#
variable vsphere_server {
    type = string
}

variable vsphere_user {
    type = string
}

variable vsphere_password {
    type = string
}

variable vsphere_datacenter {
    type = string
}

#
# Networking
#
variable external_network {
    type = string
}

variable external_network_ipv4_gateway {
    type = string
}

variable external_network_ipv4_netmask {
    type = number
    default = 24
}

variable internal_network {
    type = string
}

variable internal_network_ipv4_gateway {
    type = string
}

variable internal_network_ipv4_netmask {
    type = number
    default = 24
}

variable dns_domain {
    type = string
}

variable dns_servers {
    type = list(string)
}

variable dns_suffix_list {
    type = list(string)
}

#
# VM Template
#
variable vm_template_name {
    type = string
}

#
# Resource Pool
#
variable vsphere_resource_pool {
    type = string
}

#
# Kafka Broker
#
variable kafka_broker_cpu {
    type = number
    default = 8
}

variable kafka_broker_ram {
    type = number
    default = 8192
}

variable kafka_broker_os_dir_size_gb {
    type = number
    default = 100
}

variable kafka_broker_data_dir_size_gb {
    type = number
    default = 128
}

#
# Kafka Zookeeper
#
variable zookeeper_cpu {
    type = number
    default = 2
}

variable zookeeper_ram {
    type = number
    default = 8192
}

variable zookeeper_os_dir_size_gb {
    type = number
    default = 100
}

variable zookeeper_data_dir_size_gb {
    type = number
    default = 128
}

#
# Kafka Connect
#
variable kafka_connect_cpu {
    type = number
    default = 2
}

variable kafka_connect_ram {
    type = number
    default = 8192
}

variable kafka_connect_os_dir_size_gb {
    type = number
    default = 100
}

#
# Control Center
#
variable control_center_cpu {
    type = number
    default = 8
}

variable control_center_ram {
    type = number
    default = 32768
}

variable control_center_os_dir_size_gb {
    type = number
    default = 100
}

variable control_center_data_dir_size_gb {
    type = number
    default = 128
}

#
# Cluster 1
#
variable vsphere_cluster_1 {
    type = string
}

variable vsphere_cluster_1_datastore {
    type = string
}

variable vsphere_cluster_1_dvs {
    type = string
}

variable vsphere_cluster_1_hosts {
    type = list(string)
}

variable cluster_1_kafka_broker_count {
    type = number
    default = 4
}

variable cluster_1_kafka_broker_external_ips {
    type = list(string)
}

variable cluster_1_kafka_broker_internal_ips {
    type = list(string)
}

variable cluster_1_zookeeper_count {
    type = number
    default = 3
}

variable cluster_1_zookeeper_external_ips {
    type = list(string)
}

variable cluster_1_zookeeper_internal_ips {
    type = list(string)
}

variable cluster_1_kafka_connect_count {
    type = number
    default = 3
}

variable cluster_1_kafka_connect_ips {
    type = list(string)
}

variable cluster_1_control_center_ip {
    type = string
}

