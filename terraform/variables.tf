#
# vSphere vCenter Server
#
variable vcenter_server {
  description = "vCenter Server hostname or IP"
  type        = string
}

variable vcenter_user {
  description = "vCenter Server username"
  type        = string
}

variable vcenter_password {
  description = "vCenter Server password"
  type        = string
}

variable vcenter_insecure_ssl {
  description = "Allow insecure connection to the vCenter server (unverified SSL certificate)"
  type        = bool
  default     = false
}

# Content Library
variable content_library_name {
  type    = string
  default = "Content Library Kafka"
}

variable content_library_description {
  type    = string
  default = "Contains the template for Kafka automation."
}

#
# Template
#
variable template_ova {
  type = string
}

variable template_name {
  type = string
}

variable template_description {
  type = string
}

variable template_boot {
  type    = string
  default = "efi"
}


#
# vSphere Variables
# -----------------------------------------------------------------------------
# Datacenter
variable "vsphere_datacenter" {
  type = string
}

# Cluster
variable "vsphere_compute_cluster" {
  type = string
}

# Resource Pool
variable "vsphere_resource_pool" {
  type = string
}

# Network 1 Distributed Portgroup
variable "vsphere_network_1_portgroup" {
  type = string
}

# Network 1 IPv4 Subnet (CIDR)
variable "vsphere_network_1_ipv4_subnet_cidr" {
  type = string
}

# Network 1 IPv4 IP List
variable "vsphere_network_1_ipv4_ips" {
  type = list(string)
}

# Network 1 IPv4 Gateway
variable "vsphere_network_1_ipv4_gateway" {
  type = string
}

# Network 2 Distributed Portgroup
variable "vsphere_network_2_portgroup" {
  type = string
}

# Network 2 IPv4 Subnet (CIDR)
variable "vsphere_network_2_ipv4_subnet_cidr" {
  type = string
}

# Network 2 IPv4 IP List
variable "vsphere_network_2_ipv4_ips" {
  type = list(string)
}

# Datastore
variable "vsphere_datastore" {
  type = string
}

variable "vsphere_folder_vm" {
  type    = string
  default = "mssql-linux"
}

#
# Network
# -----------------------------------------------------------------------------
# Domain Name
variable "network_domain_name" {
  type = string
}

# Domain Name
variable "network_ipv4_dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

# Domain Name
variable "network_dns_suffix" {
  type    = list(string)
  default = []
}

#
# VM Kafka
# -----------------------------------------------------------------------------
variable "vm_kafka_prefix" {
  type    = string
  default = "kafka"
}

variable vm_kafka_broker_count_per_cluster {
  type    = number
  default = 4
}

variable vm_kafka_zookeeper_count_per_cluster {
  type    = number
  default = 3
}

variable vm_kafka_connect_count_per_cluster {
  type    = number
  default = 3
}

variable vm_kafka_control_center {
  type = object({
    cpu          = number
    memory_gb    = number
    os_disk_gb   = number
    data_disk_gb = number
  })
}

variable vm_kafka_broker {
  type = object({
    cpu             = number
    memory_gb       = number
    os_disk_gb      = number
    data_disk_count = number
    data_disk_gb    = number
  })
}

variable vm_kafka_zookeeper {
  type = object({
    cpu             = number
    memory_gb       = number
    os_disk_gb      = number
    data_disk_count = number
    data_disk_gb    = number
  })
}

variable vm_kafka_connect {
  type = object({
    cpu        = number
    memory_gb  = number
    os_disk_gb = number
  })
}
