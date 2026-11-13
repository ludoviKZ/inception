NAME := inception
COMPOSE := docker compose -f srcs/docker-compose.yml --env-file srcs/.env

.PHONY: all build up down stop start restart logs ps clean fclean re

all: up

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean: down

fclean: down
	docker volume rm $$(docker volume ls -q | grep '^inception_' || true)
	docker system prune -af

re: fclean all
