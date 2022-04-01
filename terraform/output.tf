output "kafka" {
  value = module.kafka
  sensitive = true
}


#
# Inventory File
#
module "inventory" {
  source  = "./modules/inventory"
  input = module.kafka
  output_folder = "./"
}