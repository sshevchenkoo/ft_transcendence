resource "hcloud_server" "vm" {
  name        = var.name
  server_type = var.server_type
  location    = var.location
  image       = var.image
  ssh_keys    = var.ssh_key_ids
  labels      = var.labels

  # FIX: firewall_ids принимает number, не string
  firewall_ids = var.firewall_ids

  network {
    network_id = var.network_id
    ip         = var.private_ip
  }

  # FIX: явная зависимость от subnet — сервер не создаётся до готовности сети
  depends_on = [var.subnet_id]

  # Python3 нужен Ansible для выполнения модулей
  user_data = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - python3
  EOT
}
