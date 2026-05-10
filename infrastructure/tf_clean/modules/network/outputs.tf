output "network_id" {
  description = "ID приватной сети Hetzner"
  value       = hcloud_network.main.id
}

output "subnet_id" {
  description = "ID подсети"
  value       = hcloud_network_subnet.main.id
}
