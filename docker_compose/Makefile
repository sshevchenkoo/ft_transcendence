.PHONY: dev dev-down dev-clean logs shell migrate fclean re

# Поднять всё локально
dev:
	docker compose up --build

# Тихо, без логов в терминале
dev-bg:
	docker compose up --build -d

# Остановить
dev-down:
	docker compose down

# Снести всё включая данные БД (осторожно!)
dev-clean:
	docker compose down -v --remove-orphans

# Пересобрать и запустить заново
re: dev-clean dev

# Логи конкретного сервиса: make logs s=backend
logs:
	docker compose logs -f $(s)

# Войти в shell Django контейнера
shell:
	docker compose exec backend python manage.py shell

# Войти в bash контейнера: make bash s=backend
bash:
	docker compose exec $(s) /bin/sh

# Применить миграции
migrate:
	docker compose exec backend python manage.py migrate

# Создать миграции
makemigrations:
	docker compose exec backend python manage.py makemigrations

# Создать суперпользователя
createsuperuser:
	docker compose exec backend python manage.py createsuperuser

# Собрать статику
collectstatic:
	docker compose exec backend python manage.py collectstatic --noinput

# Статус контейнеров
status:
	docker compose ps

dump:
	docker compose exec backend python manage.py dumpdata core --indent 2 --output fixtures/data.json
	@echo "Данные сохранены в fixtures/data.json"

# Загрузить данные из файла
restore:
	docker compose exec backend python manage.py loaddata fixtures/data.json
	@echo "Данные загружены"

# fix #7: используем $(MAKE) вместо make, чтобы команды выполнялись последовательно
# и передавали переменные окружения корректно
start:
	@$(MAKE) dev-bg
	@echo "Waiting for database..."
	@until docker compose exec db pg_isready -U $${POSTGRES_USER:-transcendence}; do sleep 1; done
	@$(MAKE) migrate
	@$(MAKE) restore

finish:
	@$(MAKE) dump && $(MAKE) dev-clean

# Почистить все неиспользуемые Docker образы/тома (глобально!)
fclean:
	docker system prune -af --volumes
