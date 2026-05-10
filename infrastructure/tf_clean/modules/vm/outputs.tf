output "public_ip" {
  description = "Публичный IPv4 адрес сервера"
  value       = hcloud_server.vm.ipv4_address
}

output "private_ip" {
  description = "Приватный IP в сети Hetzner"
  value       = var.private_ip
}

output "server_id" {
  description = "ID сервера в Hetzner"
  value       = hcloud_server.vm.id
}
