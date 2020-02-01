#!/bin/bash

# Check if .env file already exists
ENV_FILE=.env
if [ -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE already exists"
    exit 0
fi

# Determine project name based on current directory name
project_name=${PWD##*/}
echo Your project name will be ${project_name}

# Set the project name in the Makefile
sed -i "" 's/PROJECT_NAME := myproject/PROJECT_NAME := '${project_name}'/g' Makefile

# Set project name in the .env file
echo "COMPOSE_PROJECT_NAME="${project_name} >> .env
#sed -i "" 's/COMPOSE_PROJECT_NAME=/COMPOSE_PROJECT_NAME='${project_name}'/g' .env
echo COMPOSE_PROJECT_NAME set to \"${project_name}\" in the .env file

# Ask for external port suffix number
echo Enter the port suffix number for al the services that should be reachable \(mysql/redis/nginx\)
read port_suffix

# Set the chosen port suffix in the .env file
echo "EXTERNAL_PORT_SUFFIX="${port_suffix} >> .env
echo EXTERNAL_PORT_SUFFIX set to \"${port_suffix}\" in the .env file

# Build the services
echo Building the services..
make up

# Remove the public directory
echo Removing the public directory
rm -rf src/public

# Install the latest Laravel version
echo Installing the latest version of Laravel in /src
docker exec ${project_name}-php composer create-project --prefer-dist laravel/laravel ./

# Running initial composer install
echo Running initial composer install..
docker exec ${project_name}-php composer install

# Restarting all the services
echo Restarting the services
make restart

# Scaffolding the authentication lsb_release -a
docker exec ${project_name}-php php artisan make:auth

# Display final instructions
echo Now go to http://localhost:80${port_suffix} and edit your src/.env file as needed and run 'make' to see the available commands..
echo To enable Tailwind style authentication, run the following commands:
echo 1. make bash
echo 2. npx use-tailwind-preset