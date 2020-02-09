#!/bin/bash

#remove-all: down remove-image-all remove-volume-all ## Remove all project conatiners, images and volumes
#
#remove-image-all: remove-image-php remove-image-nginx ## Remove all project images
#
#remove-image-php: ## Remove project php image
#	docker image rm --force $(COMPOSE_PROJECT_NAME)-php
#
#remove-image-nginx: ## Remove project nginx image
#	docker image rm --force $(COMPOSE_PROJECT_NAME)-nginx
#
#remove-volume-all: remove-volume-mysql remove-volume-redis ## Remove all project volumes
#
#remove-volume-mysql: ## Remove project mysql volume
#	docker volume rm --force $(COMPOSE_PROJECT_NAME)-mysql
#
#remove-volume-redis: ## Remove project redis volume
#	docker volume rm --force $(COMPOSE_PROJECT_NAME)-redis