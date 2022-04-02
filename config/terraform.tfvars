# This file contains all the parameters required by Terraform
# in order to connect and identify the resources to use in the
# target vSphere cluster.

#
# vCenter Server Configuration
#
# vCenter Hostname or IP
vcenter_server = "wdc-w02-vc01.vcf01.isvlab.vmware.com"

# Username
vcenter_user = "administrator@vsphere.local"

# Password
vcenter_password = "P@ssword123!"

# Allow unverified SSL connection
vcenter_insecure_ssl = true

#
# vSphere Configuration
#
# vSphere Datacenter.
# This resource must exist.
vsphere_datacenter = "wdc-w02-DC"

# vSphere Cluster in the Datacenter.
# This resource must exist.
vsphere_compute_cluster = "wdc-w02-cl01"

# vSphere VM Folder containing the created VM.
# This resource must not exist and will be created by Terraform. <---
vsphere_folder_vm = "kafka"

# vSphere Resource Pool where the VM will be created.
# This resource must not exist and will be created by Terraform. <---
vsphere_resource_pool = "kafka"

# vSphere Distributed Switch PortGroup 1.
# This resource must exist.
vsphere_network_1_portgroup = "wdc-w02-vlan1003"

# Subnet for PortGroup 1.
# This must be configured in CIDR format "network/mask" (e.g. "10.0.0.0/8")
vsphere_network_1_ipv4_subnet_cidr = "172.16.20.0/23"

# List of IP addresses for PortGroup 1 that will be used for the created VM.
# There must be as many IP as the requested number of MSSQL VM nodes (see 'vm_mssql_count').
# The IP addresses must not be in use.
vsphere_network_1_ipv4_ips = [
  "172.16.20.222",
  "172.16.20.223",
  "172.16.20.224",
  "172.16.20.225",
  "172.16.20.226",
  "172.16.20.227",
  "172.16.20.228",
  "172.16.20.229",
  "172.16.20.230",
  "172.16.20.231",
  "172.16.20.232",
]

# Address of the gateway for the PortGroup 1 subnet.
vsphere_network_1_ipv4_gateway = "172.16.21.253"

# vSphere Distributed Switch PortGroup 2.
# This resource must exist.
vsphere_network_2_portgroup = "wdc-w02-vlan1004"

# Subnet for PortGroup 2.
# This must be configured in CIDR format "network/mask" (e.g. "10.0.0.0/8")
vsphere_network_2_ipv4_subnet_cidr = "172.16.22.0/23"

# List of IP addresses for PortGroup 2 that will be used for the created VM.
# There must be as many IP as the requested number of MSSQL VM nodes (see 'vm_mssql_count').
# The IP addresses must not be in use.
vsphere_network_2_ipv4_ips = [
  "172.16.22.222",
  "172.16.22.223",
  "172.16.22.224",
  "172.16.22.225",
  "172.16.22.226",
  "172.16.22.227",
  "172.16.22.228",
  "172.16.22.229",
  "172.16.22.230",
  "172.16.22.231",
  "172.16.22.232",
]

# The target Datastore for the created VM.
# This resource must exist and have sufficient available capacity.
vsphere_datastore = "wdc-w02-wdc-w02-vc01-wdc-w02-cl01-vsan01"

#
# Network
#
# Domain that will be appended to the hostname
network_domain_name = "isvlab.vmware.com"

# DNS servers that will be configured on the created VM
network_ipv4_dns_servers = ["172.16.16.16", "172.16.16.17"]

# DNS suffix search list
network_dns_suffix = ["isvlab.vmware.com"]
