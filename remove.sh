#!/bin/bash

# Get container-prefix from the docker-compose .env file
COMPOSE_PROJECT_NAME="$(grep COMPOSE_PROJECT_NAME .env | xargs)"
IFS='=' read -ra COMPOSE_PROJECT_NAME <<< "$COMPOSE_PROJECT_NAME"
CONTAINER_PREFIX="${COMPOSE_PROJECT_NAME[1]}"

# Set output colors and spacing
DEFAULT="\033[0m"
MAIN="\033[32m"
SUB="\033[33m"

./develop.sh down

printf "\n"

read -p "Remove the PHP and NGINX Docker images for this project? (y/n)" -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf "${MAIN}Removing image: ${SUB}%s${DEFAULT}\n" "${CONTAINER_PREFIX}"-php
  docker image rm --force "${CONTAINER_PREFIX}"-php > /dev/null

  printf "${MAIN}Removing image: ${SUB}%s${DEFAULT}\n" "${CONTAINER_PREFIX}"-nginx
  docker image rm --force "${CONTAINER_PREFIX}"-nginx > /dev/null

  printf "${MAIN}The Docker images have been removed.${DEFAULT}\n\n"
else
  printf "${SUB}The Docker images were preserved.${DEFAULT}\n\n"
fi

read -p "Remove the Redis and MySQL Docker volumes for this project? (y/n)" -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf "${MAIN}Removing volume: ${SUB}%s${DEFAULT}\n" "${CONTAINER_PREFIX}"-mysql
  docker volume rm --force "${CONTAINER_PREFIX}"-mysql > /dev/null

  printf "${MAIN}Removing volume: ${SUB}%s${DEFAULT}\n" "${CONTAINER_PREFIX}"-redis
  docker volume rm --force "${CONTAINER_PREFIX}"-redis > /dev/null

  printf "${MAIN}The Docker volumes have been removed.${DEFAULT}\n\n"
else
  printf "${SUB}The Docker volumes were preserved.${DEFAULT}\n\n"
fi

read -p "Remove the 'src' folder and the '.env' file? (y/n)" -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf "${MAIN}Removing file: ${SUB}.env${DEFAULT}\n"
  rm .env

  printf "${MAIN}Removing folder: ${SUB}/src${DEFAULT}\n"
  rm -rf src/

  printf "${MAIN}Project specific files have been removed.${DEFAULT}\n\n"

  printf "You're free to run './initialize.sh' once again.\n\n"
fi

printf "All done.\n"
exit 0