variable "name"        { type = string }
variable "server_type" { type = string }
variable "location"    { type = string }
variable "image"       { type = string }
variable "network_id"  { type = string }
variable "private_ip"  { type = string }

variable "ssh_key_ids" {
  type = list(number)   # FIX: hcloud_ssh_key.id возвращает number
}

# FIX: subnet_id передаётся чтобы Terraform знал о зависимости
variable "subnet_id" {
  type        = string
  description = "ID подсети — используется только для depends_on"
}

# FIX: firewall_ids тип number (не string)
variable "firewall_ids" {
  type = list(number)
}

variable "labels" {
  description = "Лейблы сервера — используются Ansible hcloud плагином для группировки"
  type        = map(string)
  default     = {}
}
