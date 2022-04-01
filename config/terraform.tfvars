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
vsphere_folder_vm = "mssql"

# vSphere Resource Pool where the VM will be created.
# This resource must not exist and will be created by Terraform. <---
vsphere_resource_pool = "mssql"

# vSphere Distributed Switch PortGroup.
# This resource must exist.
vsphere_network_1_portgroup = "wdc-w02-vlan1003"

# Subnet for the PortGroup.
# This must be configured in CIDR format "network/mask" (e.g. "10.0.0.0/8")
vsphere_network_1_ipv4_subnet_cidr = "172.16.20.0/23"

# List of IP addresses that will be used for the created VM.
# There must be as many IP as the requested number of MSSQL VM nodes (see 'vm_mssql_count').
# The IP addresses must not be in use.
vsphere_network_1_ipv4_ips = ["172.16.20.222", "172.16.20.223", "172.16.20.224"]

# Address of the gateway for the PortGroup subnet.
vsphere_network_1_ipv4_gateway = "172.16.21.253"

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

#
# VM MSSQL
#
# The prefix for the VM create in the
vm_mssql_prefix = "mssql-linux"

# The number of MSSQL VM to create.
# Currently this project only support nodes counts of 3 or 5. The SQL Server Linux AG
# replica are configured with the synchronized commit option.
vm_mssql_count = 3

# The VM hardware configuration
vm_mssql = {
    cpu = 8            # Number of vCPU
    memory_gb = 32     # Amount of RAM in GB
    os_disk_gb = 60    # Size of the OS disk
    data_disk_gb = 100 # Size of the disk where the MSSQL data will reside
    log_disk_gb  = 40  # Size of the disk where the MSSQL log will reside
}
