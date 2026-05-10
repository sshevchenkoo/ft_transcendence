output "k3s_firewall_id" {
  description = "ID файрвола для k3s нод"
  value       = hcloud_firewall.k3s.id
}

output "db_firewall_id" {
  description = "ID файрвола для PostgreSQL"
  value       = hcloud_firewall.db.id
}
