.DEFAULT_GOAL:=help
SHELL:=/bin/bash
COMPOSE_PROJECT_NAME = myapp


##@ Docker
.PHONY: build containers down enter images restart restart-down stop up

build:  ## Build all images
	docker-compose build --no-cache

containers: ## List all containers
	docker ps -a

down:  ## Stop and remove all containers
	docker-compose down

enter: ## Run bash inside php container
	docker exec -it $(COMPOSE_PROJECT_NAME)-php bash

images: ## List all images
	docker images

restart: stop up ## Stop and start all containers

restart-down: down up ## Stop, remove and start all containers

stop:  ## Stop all containers
	docker-compose stop

up:  ## Create all containers
	docker-compose up -d


##@ Building
.PHONY: composer-install composer-install-dry composer-update composer-update-dry composer-version

composer-install: ## Run composer install
	docker-compose exec $(COMPOSE_PROJECT_NAME)-php composer --version

composer-install-dry: ## Run composer install --dry-run
	docker-compose exec $(COMPOSE_PROJECT_NAME)-php composer install --dry-run

composer-update: ## Run composer update
	docker-compose exec $(COMPOSE_PROJECT_NAME)-php composer update

composer-update-dry: ## Run composer update --dry-run
	docker-compose exec $(COMPOSE_PROJECT_NAME)-php composer update --dry-run

composer-version: ## Get composer version
	docker-compose exec $(COMPOSE_PROJECT_NAME)-php composer --version


##TODO##@ Testing
##TODO:.PHONY: test unit feature stan coverage


##@ Logging
.PHONY: log log-mysql log-nginx log-php log-redis

log: ## Show all logs
	docker-compose logs --follow

log-mysql: ## Show mysql logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-mysql

log-nginx: ## Show nginx logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-nginx

log-php: ## Show php logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-php

log-redis: ## Show redis logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-redis


##@ Helpers
.PHONY: help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

## PROJECT: create
## ARTISAN: migrate, fresh
## NPM: watch, run-dev, run-prod
## QUALITY: cs