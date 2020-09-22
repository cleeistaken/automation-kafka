resource "local_file" "inventory" {
  content  = templatefile("${path.module}/inventory.yml.tpl", { kafka = var.kafka })
  filename = "${var.output_folder}/inventory.yml"
  file_permission = "644"
}

