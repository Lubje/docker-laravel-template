include .env

.DEFAULT_GOAL := help
SHELL := /bin/bash


##@ Docker(-compose)

bash: ## Run bash inside php container
	docker exec -it $(COMPOSE_PROJECT_NAME)-php bash

build:  ## Build all images
	docker-compose build --no-cache

down:  ## Stop and remove all containers
	docker-compose down

restart: stop up ## Stop and start all containers

restart-down: down up ## Stop, remove and start all containers

stop:  ## Stop all containers
	docker-compose stop

up:  ## Create all containers
	docker-compose up -d


##@ Building (composer)

composer-install: ## Run composer install
	docker exec $(COMPOSE_PROJECT_NAME)-php composer install

composer-install-dry: ## Run composer install --dry-run
	docker exec $(COMPOSE_PROJECT_NAME)-php composer install --dry-run

composer-outdated: ## Run composer outdated
	docker exec $(COMPOSE_PROJECT_NAME)-php composer outdated

composer-update: ## Run composer update
	docker exec $(COMPOSE_PROJECT_NAME)-php composer update

composer-update-dry: ## Run composer update --dry-run
	docker exec $(COMPOSE_PROJECT_NAME)-php composer update --dry-run

composer-version: ## Get composer version
	docker exec $(COMPOSE_PROJECT_NAME)-php composer --version


##@ Building (npm)

run-dev: ## Run npm run dev
	docker exec -it $(COMPOSE_PROJECT_NAME)-php npm run dev

run-prod: ## Run npm run prod
	docker exec -it $(COMPOSE_PROJECT_NAME)-php npm run prod

watch: ## Run npm run watch
	docker exec -it $(COMPOSE_PROJECT_NAME)-php npm run watch


##@ Testing

test: ## Run phpunit
	docker exec -it -w /var/www/html $(COMPOSE_PROJECT_NAME)-php ./vendor/bin/phpunit $$([[ -n "$(filter)" ]] && echo "--filter $(filter)")


##@ Logging

logs: ## Show all logs
	docker-compose logs --follow

log-mysql: ## Show mysql logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-mysql

log-nginx: ## Show nginx logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-nginx

log-php: ## Show php logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-php

log-redis: ## Show redis logs
	docker logs --follow --timestamps --tail=100 $(COMPOSE_PROJECT_NAME)-redis


##@ Removal

remove-all: down remove-image-all remove-volume-all ## Remove all project conatiners, images and volumes

remove-image-all: remove-image-php remove-image-nginx ## Remove all project images

remove-image-php: ## Remove project php image
	docker image rm --force $(COMPOSE_PROJECT_NAME)-php

remove-image-nginx: ## Remove project nginx image
	docker image rm --force $(COMPOSE_PROJECT_NAME)-nginx

remove-volume-all: remove-volume-mysql remove-volume-redis ## Remove all project volumes

remove-volume-mysql: ## Remove project mysql volume
	docker volume rm --force $(COMPOSE_PROJECT_NAME)-mysql

remove-volume-redis: ## Remove project redis volume
	docker volume rm --force $(COMPOSE_PROJECT_NAME)-redis


##@ Helpers

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


## TODO:
## ARTISAN: migrate, fresh
## TESTING: test-unit test-feature stan coverage