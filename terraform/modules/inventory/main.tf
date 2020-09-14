resource "local_file" "inventory" {
  content  = templatefile("${path.module}/inventory.yml.tpl", { es_nodes = var.es_nodes, rally_nodes = var.rally_nodes })
  filename = "${var.output_folder}/inventory.yml"
  file_permission = "644"
}
