#!/bin/bash

# Get container-prefix from the docker-compose .env file
COMPOSE_PROJECT_NAME="$(grep COMPOSE_PROJECT_NAME .env | xargs)"
IFS='=' read -ra COMPOSE_PROJECT_NAME <<< "$COMPOSE_PROJECT_NAME"
CONTAINER_PREFIX="${COMPOSE_PROJECT_NAME[1]}"

# Set output colors and spacing
DEFAULT="\033[0m"
MAIN="\033[32m"
SUB="\033[33m"

read -p "Remove all Docker images for this project? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf "${MAIN}Removing: ${SUB}%s${DEFAULT}..\n" "${CONTAINER_PREFIX}"-mysql
  docker image rm --force "${CONTAINER_PREFIX}"-mysql

  printf "${MAIN}Removing: ${SUB}%s${DEFAULT}..\n" "${CONTAINER_PREFIX}"-redis
  docker image rm --force "${CONTAINER_PREFIX}"-redis

  printf "${MAIN}Removing: ${SUB}%s${DEFAULT}..\n" "${CONTAINER_PREFIX}"-php
  docker image rm --force "${CONTAINER_PREFIX}"-php

  printf "${MAIN}Removing: ${SUB}%s${DEFAULT}..\n" "${CONTAINER_PREFIX}"-nginx
  docker image rm --force "${CONTAINER_PREFIX}"-nginx

  printf "${MAIN}The Docker images have been removed.${DEFAULT}\n"
else
  printf "${SUB}The Docker images were preserved.${DEFAULT}\n"
fi

read -p "Remove corresponding Redis and MySQL volumes? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf "${MAIN}Removing volume: ${SUB}%s${DEFAULT}..\n" "${CONTAINER_PREFIX}"-mysql
  docker volume rm --force "${CONTAINER_PREFIX}"-mysql

  printf "${MAIN}Removing volume: ${SUB}%s${DEFAULT}..\n" "${CONTAINER_PREFIX}"-redis
  docker volume rm --force "${CONTAINER_PREFIX}"-redis

  printf "${MAIN}The corresponding volumes have been removed.${DEFAULT}\n"
else
  printf "${SUB}The corrseponding volumes were preserved.${DEFAULT}\n"
fi

echo All done.

exit 0