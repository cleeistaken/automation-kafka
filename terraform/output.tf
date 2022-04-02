output "kafka" {
  value = module.kafka
  sensitive = true
}


#
# Inventory File
#
module "inventory" {
  source  = "./modules/inventory"

  # Environment information
  input = module.kafka

   # vCenter
  vsphere_server = var.vcenter_server
  user = var.vcenter_user
  password = var.vcenter_password
  allow_unverified_ssl = var.vcenter_insecure_ssl

  # Output file location
  output_folder = "../config"
}