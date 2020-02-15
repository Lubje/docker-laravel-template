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
echo Enter a number to use as port-suffix and press enter. We want to avoid port collisions with possible other services.
echo For example, entering \"4\" will result in the following ports being used: 33064\(MySQL\), 63794\(Redis\), 804\(NGINX\).
read -r port_suffix

# Set the chosen port suffix in the .env file
echo "EXTERNAL_PORT_SUFFIX=""${port_suffix}" >> .env
echo EXTERNAL_PORT_SUFFIX set to \""${port_suffix}"\" in the .env file.

# Create the needed external network if it does not yet exists
if [ ! "$(docker network ls | grep external)" ]; then
  echo "Creating network 'external'.."
  docker network create external
fi

# Build the services
echo Building the services..
./develop.sh up

# Remove the public directory. It will already exist in the Laravel project code base.
rm -rf src/public

printf "\n"

# Ask confirmation to create a fresh Laravel project
read -p "For a fresh Laravel project, press 'y'. For using one of your own repositories, press 'n'" -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install the latest Laravel version
  printf "Installing the latest version of Laravel in /src:/var/www/html..\n"
  ./develop.sh composer create-project --prefer-dist laravel/laravel /var/www/html

  # Restart all the services
  printf "\n"
  printf "Restarting the services..\n"
  ./develop.sh restart

  # Display final instructions
  printf "\n"
  printf "Your project is available at http://localhost:80%s\n" "${port_suffix}"
  printf "Configure your 'src/.env' file as needed and restart with './develop.sh restart'\n\n"

  printf "For a list of available commands run './develop.sh'.\n\n"

  printf "To enable Tailwind based authentication scaffolding, run the following commands:\n"
  printf "1. ./develop.sh bash\n"
  printf "2. npx use-tailwind-preset\n"
  exit 0
fi

# Display final instructions
printf "\n"
printf "You can now clone your own Laravel project into the '/src' directory.\n\n"

printf "After cloning, don't forget to:\n"
printf "1. Create the .env file\n"
printf "2. Generate the application key\n"
printf "3. Install composer dependencies\n\n"

printf "For a list of available commands run './develop.sh'.\n\n"

printf "Your project will be available at http://localhost:80%s\n" "${port_suffix}"
exit 0
