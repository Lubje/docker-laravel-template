.DEFAULT_GOAL := help
SHELL := /bin/bash
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_NAME := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))


##@ Docker

bash: ## Run bash inside php container
	docker exec -it $(PROJECT_NAME)-php bash

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


##@ Building

composer-install: ## Run composer install
	docker exec $(PROJECT_NAME)-php composer install

composer-install-dry: ## Run composer install --dry-run
	docker exec $(PROJECT_NAME)-php composer install --dry-run

composer-update: ## Run composer update
	docker exec $(PROJECT_NAME)-php composer update

composer-update-dry: ## Run composer update --dry-run
	docker exec $(PROJECT_NAME)-php composer update --dry-run

composer-version: ## Get composer version
	docker exec $(PROJECT_NAME)-php composer --version


# ##@ Building (npm)
#
#run-dev: ## Run npm run dev
#	docker-compose exec $(PROJECT_NAME)-php npm run dev
#
#run-prod: ## Run npm run prod
#	docker-compose exec $(PROJECT_NAME)-php npm run prod
#
#watch: ## Run npm run watch
#	docker-compose exec $(PROJECT_NAME)-php npm run watch


##@ Testing
.PHONY: test test-unit test-feature stan coverage

test: ## Run phpunit
		docker exec -it -w /var/www/html $(PROJECT_NAME)-php ./vendor/bin/phpunit $$([[ -n "$(filter)" ]] && echo "--filter $(filter)")


##@ Logging

log: ## Show all logs
	docker-compose logs --follow

log-mysql: ## Show mysql logs
	docker logs --follow --timestamps --tail=100 $(PROJECT_NAME)-mysql

log-nginx: ## Show nginx logs
	docker logs --follow --timestamps --tail=100 $(PROJECT_NAME)-nginx

log-php: ## Show php logs
	docker logs --follow --timestamps --tail=100 $(PROJECT_NAME)-php

log-redis: ## Show redis logs
	docker logs --follow --timestamps --tail=100 $(PROJECT_NAME)-redis


##@ Helpers

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

## PROJECT: create
## ARTISAN: migrate, fresh
## NPM: watch, run-dev, run-prod
## QUALITY: cs