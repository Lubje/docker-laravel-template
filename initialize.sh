#!/bin/bash

# Check if .env file already exists
ENV_FILE=.env
if [ -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE already exists!"
    exit 0
fi

# Create src/public folder needed for volume mounting in docker-compose file
mkdir -p src/public

# Determine project name based on current directory name
project_name=${PWD##*/}

# Set project name in the .env file
echo "COMPOSE_PROJECT_NAME=""${project_name}" >> .env
echo COMPOSE_PROJECT_NAME set to \""${project_name}"\" in the .env file.

# Ask for external port suffix number
echo Enter a number to use as port-suffix and press enter, to make the external ports unique.
echo For example, entering \"4\" will result in the following ports being used: 33064\(MySQL\), 63794\(Redis\), 804\(NGINX\).
read -r port_suffix

# Set the chosen port suffix in the .env file
echo "EXTERNAL_PORT_SUFFIX=""${port_suffix}" >> .env
echo EXTERNAL_PORT_SUFFIX set to \""${port_suffix}"\" in the .env file.

# Build the services
echo Building the services..
make up

# Remove the public directory, Laravel needs an empty directory for installation
echo Removing the public directory to enable Laravel intallation..
rm -rf src/public

# Install the latest Laravel version
echo Installing the latest version of Laravel in /src:/var/www/html..
docker exec "${project_name}"-php composer create-project --prefer-dist laravel/laravel /var/www/html

# Run initial composer install
echo Running initial composer install..
docker exec "${project_name}"-php composer install

# Restart all the services
echo Restarting the services..
make restart

# Display final instructions
echo Now go to http://localhost:80"${port_suffix}" and edit your src/.env file as needed and run \"make\" to see the available commands.
echo To enable Tailwind style authentication, run the following commands:
echo 1. make bash
echo 2. npx use-tailwind-preset