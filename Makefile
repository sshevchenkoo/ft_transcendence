.PHONY: help keys check-keys check-tfvars infra-up infra-down infra-plan configure ping deploy all fclean

# ─── Пути ─────────────────────────────────────────────────────────────────────
ROOT_DIR    := $(shell pwd)
SSH_DIR     := $(ROOT_DIR)/.ssh
SSH_KEY     := $(SSH_DIR)/id_ed25519
SSH_KEY_PUB := $(SSH_DIR)/id_ed25519.pub
TF_DIR      := $(ROOT_DIR)/infrastructure/tf_clean
ANSIBLE_DIR := $(ROOT_DIR)/infrastructure/ansible

# ─── Цвета ────────────────────────────────────────────────────────────────────
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m

# ─── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  $(GREEN)Transcendence — управление инфраструктурой$(NC)"
	@echo ""
	@echo "  $(YELLOW)make keys$(NC)         — сгенерировать SSH ключи в .ssh/ (один раз)"
	@echo "  $(YELLOW)make infra-up$(NC)     — создать VM на Hetzner (terraform apply)"
	@echo "  $(YELLOW)make infra-plan$(NC)   — показать план без применения"
	@echo "  $(YELLOW)make infra-down$(NC)   — удалить VM на Hetzner (terraform destroy)"
	@echo "  $(YELLOW)make configure$(NC)    — настроить серверы (ansible)"
	@echo "  $(YELLOW)make ping$(NC)         — проверить что ansible видит хосты"
	@echo "  $(YELLOW)make deploy$(NC)       — задеплоить k8s манифесты"
	@echo "  $(YELLOW)make all$(NC)          — полный пайплайн: keys → infra-up → configure"
	@echo "  $(YELLOW)make fclean$(NC)       — снести всё (destroy + удалить .ssh/)"
	@echo ""

# ─── SSH ключи ────────────────────────────────────────────────────────────────
keys:
	@if [ -f "$(SSH_KEY)" ]; then \
		echo "$(YELLOW)SSH ключ уже есть: $(SSH_KEY)$(NC)"; \
	else \
		mkdir -p $(SSH_DIR); \
		ssh-keygen -t ed25519 -C "transcendence-deploy" -f $(SSH_KEY) -N ""; \
		chmod 700 $(SSH_DIR); \
		chmod 600 $(SSH_KEY); \
		chmod 644 $(SSH_KEY_PUB); \
		echo "$(GREEN)SSH ключи созданы в $(SSH_DIR)$(NC)"; \
	fi

check-keys:
	@if [ ! -f "$(SSH_KEY)" ]; then \
		echo "$(RED)SSH ключ не найден. Запусти: make keys$(NC)"; \
		exit 1; \
	fi

check-tfvars:
	@if [ ! -f "$(TF_DIR)/terraform.tfvars" ]; then \
		echo "$(RED)Файл terraform.tfvars не найден!$(NC)"; \
		echo "  cp $(TF_DIR)/terraform.tfvars.example $(TF_DIR)/terraform.tfvars"; \
		echo "  Заполни hcloud_token и your_ssh_ip"; \
		exit 1; \
	fi

# ─── Terraform ────────────────────────────────────────────────────────────────
infra-up: check-keys check-tfvars
	@echo "$(GREEN)Поднимаем инфраструктуру на Hetzner...$(NC)"
	cd $(TF_DIR) && terraform init -upgrade
	cd $(TF_DIR) && terraform apply \
		-var="ssh_public_key=$$(cat $(SSH_KEY_PUB))" \
		-auto-approve
	@echo "$(GREEN)Готово! IP адреса:$(NC)"
	cd $(TF_DIR) && terraform output

infra-plan: check-keys check-tfvars
	cd $(TF_DIR) && terraform init -upgrade
	cd $(TF_DIR) && terraform plan \
		-var="ssh_public_key=$$(cat $(SSH_KEY_PUB))"

infra-down: check-keys check-tfvars
	@echo "$(RED)Удаляем инфраструктуру на Hetzner...$(NC)"
	cd $(TF_DIR) && terraform destroy \
		-var="ssh_public_key=$$(cat $(SSH_KEY_PUB))" \
		-auto-approve
	@echo "$(GREEN)Инфраструктура удалена$(NC)"

# ─── Вспомогательный макрос: читает hcloud_token из terraform.tfvars ─────────
# Работает с одинарными и двойными кавычками, пробелами вокруг "="
define get_hcloud_token
$(shell sed -n 's/^[[:space:]]*hcloud_token[[:space:]]*=[[:space:]]*["'"'"']\(.*\)["'"'"'][[:space:]]*/\1/p' $(TF_DIR)/terraform.tfvars)
endef

# ─── Ansible ──────────────────────────────────────────────────────────────────
# Ждём 30 сек после terraform — VM должна загрузиться
configure: check-keys
	@echo "$(YELLOW)Ждём 30 сек пока VM загрузятся...$(NC)"
	@sleep 30
	@echo "$(GREEN)Настраиваем серверы через Ansible...$(NC)"
	cd $(ANSIBLE_DIR) && \
		HCLOUD_TOKEN="$(call get_hcloud_token)" \
		ANSIBLE_PRIVATE_KEY_FILE=$(SSH_KEY) \
		ansible-playbook site.yml --ask-vault-pass
	@echo "$(GREEN)Серверы настроены!$(NC)"

# Проверить что Ansible видит все хосты
ping: check-keys
	cd $(ANSIBLE_DIR) && \
		HCLOUD_TOKEN="$(call get_hcloud_token)" \
		ANSIBLE_PRIVATE_KEY_FILE=$(SSH_KEY) \
		ansible all -m ping

# ─── Deploy ───────────────────────────────────────────────────────────────────
deploy: check-keys
	@MASTER_IP=$$(cd $(TF_DIR) && terraform output -raw master_public_ip); \
	echo "$(GREEN)Деплоим манифесты на $$MASTER_IP ...$(NC)"; \
	ssh -i $(SSH_KEY) -o StrictHostKeyChecking=no root@$$MASTER_IP \
		"kubectl apply -f /root/k8s/"

# ─── Полный пайплайн ──────────────────────────────────────────────────────────
all: keys infra-up configure
	@echo ""
	@echo "$(GREEN)Инфраструктура готова!$(NC)"
	@echo "$(YELLOW)Следующий шаг: make deploy$(NC)"

# ─── Полная очистка ───────────────────────────────────────────────────────────
fclean: infra-down
	@echo "$(RED)Удаляем SSH ключи...$(NC)"
	rm -rf $(SSH_DIR)
	@echo "$(GREEN)Всё очищено$(NC)"
