output "kafka" {
  value = module.kafka
}

module "inventory" {
  source  = "./modules/inventory"
  kafka = module.kafka
  output_folder = "../ansible/"
}

