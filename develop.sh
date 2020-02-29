#!/bin/bash

# Get container-prefix from the docker-compose .env file
COMPOSE_PROJECT_NAME="$(grep COMPOSE_PROJECT_NAME .env | xargs)"
IFS='=' read -ra COMPOSE_PROJECT_NAME <<< "$COMPOSE_PROJECT_NAME"
CONTAINER_PREFIX="${COMPOSE_PROJECT_NAME[1]}"

# Set output colors and spacing
DEFAULT="\033[0m"
CATEGORY="\033[32m"
COMMAND="\033[33m"
SPACING="   "

if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "commands" ]; then
  printf "Available commands:\n\n"

  printf "${CATEGORY}Assets\n"
  printf "${COMMAND}  run-dev      ${SPACING}${DEFAULT}Compile assets for development\n"
  printf "${COMMAND}  run-prod     ${SPACING}${DEFAULT}Compile assets for production\n"
  printf "${COMMAND}  watch        ${SPACING}${DEFAULT}Run scripts from package.json when files change\n\n"

  printf "${CATEGORY}Composer\n"
  printf "${COMMAND}  install      ${SPACING}${DEFAULT}Install dependencies\n"
  printf "${COMMAND}  install-dry  ${SPACING}${DEFAULT}Fake install dependencies\n"
  printf "${COMMAND}  outdated     ${SPACING}${DEFAULT}List outdated dependencies\n"
  printf "${COMMAND}  update       ${SPACING}${DEFAULT}Update dependencies\n"
  printf "${COMMAND}  update-dry   ${SPACING}${DEFAULT}Fake update dependencies\n\n"

  printf "${CATEGORY}Database\n"
  printf "${COMMAND}  fresh|refresh${SPACING}${DEFAULT}Drop all tables and re-run all migrations\n"
  printf "${COMMAND}  fresh-seed   ${SPACING}${DEFAULT}Drop all tables, re-run all migrations and seeders\n"
  printf "${COMMAND}  migrate      ${SPACING}${DEFAULT}Run the database migrations\n"
  printf "${COMMAND}  seed         ${SPACING}${DEFAULT}Seed the database with records\n\n"

  printf "${CATEGORY}Docker\n"
  printf "${COMMAND}  build|rebuild${SPACING}${DEFAULT}Build the images without cache\n"
  printf "${COMMAND}  down         ${SPACING}${DEFAULT}Stop and remove the containers\n"
  printf "${COMMAND}  ps           ${SPACING}${DEFAULT}List the containers\n"
  printf "${COMMAND}  restart      ${SPACING}${DEFAULT}Restart the containers\n"
  printf "${COMMAND}  restart-down ${SPACING}${DEFAULT}Restart the containers using down\n"
  printf "${COMMAND}  stop         ${SPACING}${DEFAULT}Stop the containers\n"
  printf "${COMMAND}  up           ${SPACING}${DEFAULT}Start the containers\n\n"

  printf "${CATEGORY}Inspection\n"
  printf "${COMMAND}  coverage     ${SPACING}${DEFAULT}Run PHPunit code coverage analysis with PCOV\n"
  printf "${COMMAND}  cs|fixer     ${SPACING}${DEFAULT}Run PHP-CS-Fixer with --dry-run\n"
  printf "${COMMAND}  larastan     ${SPACING}${DEFAULT}Run static analysis\n\n"

  printf "${CATEGORY}Logging\n"
  printf "${COMMAND}  log|logs     ${SPACING}${DEFAULT}Tail logs, use optional 1st argument to specify a service (mysql,nginx,php,redis)\n\n"

  printf "${CATEGORY}Optimization\n"
  printf "${COMMAND}  cache|clear  ${SPACING}${DEFAULT}Clear all the cache\n"
  printf "${COMMAND}  ide-helper   ${SPACING}${DEFAULT}Create IDE autocompletion files\n\n"

  printf "${CATEGORY}Routes\n"
  printf "${COMMAND}  routes       ${SPACING}${DEFAULT}List all routes\n"
  printf "${COMMAND}  routes-get   ${SPACING}${DEFAULT}List all routes with GET methods\n"
  printf "${COMMAND}  routes-name  ${SPACING}${DEFAULT}List routes filtered by name, use 1st argument as filter-value\n"
  printf "${COMMAND}  routes-post  ${SPACING}${DEFAULT}List all routes with POST methods\n"
  printf "${COMMAND}  routes-path  ${SPACING}${DEFAULT}List routes filtered by path, use 1st argument as filter-value\n\n"

  printf "${CATEGORY}Testing for Laravel version < 7\n"
  printf "${COMMAND}  feature6     ${SPACING}${DEFAULT}Run feature tests, use optional 1st argument as filter-value\n"
  printf "${COMMAND}  test6|tests6 ${SPACING}${DEFAULT}Run all tests, use optional 1st argument as filter-value\n"
  printf "${COMMAND}  unit6        ${SPACING}${DEFAULT}Run unit tests, use optional 1st argument as filter-value\n\n"

  printf "${CATEGORY}Testing for Laravel version >= 7\n"
  printf "${COMMAND}  feature      ${SPACING}${DEFAULT}Run feature tests, use optional 1st argument as filter-value\n"
  printf "${COMMAND}  test|tests   ${SPACING}${DEFAULT}Run all tests, use optional 1st argument as filter-value\n"
  printf "${COMMAND}  unit         ${SPACING}${DEFAULT}Run unit tests, use optional 1st argument as filter-value\n\n"

  printf "${CATEGORY}Other\n"
  printf "${COMMAND}  artisan      ${SPACING}${DEFAULT}List artisan commands\n"
  printf "${COMMAND}  bash|enter   ${SPACING}${DEFAULT}Run bash in the php container\n"
  printf "${COMMAND}  *            ${SPACING}${DEFAULT}Will be run in the php container\n"
  exit 0
fi

# Exit if the Docker daemon is not running
dockerResponse=$(docker info --format '{{json .}}')
if echo "${dockerResponse}" | grep -q "Is the docker daemon running?"; then
  echo "Docker is not running."
  exit 1
fi

composerPackageIsInstalled () {
  docker exec -it "${CONTAINER_PREFIX}"-php composer show | grep "$1" > /dev/null
}

exitIfPhpContainerIsNotRunning () {
  if [ ! "$(docker ps -q -f name="${CONTAINER_PREFIX}"-php)" ] || [ "$(docker inspect -f '{{.State.Running}}' "${CONTAINER_PREFIX}"-php)" == "false" ]; then
      echo "Container '${CONTAINER_PREFIX}-php' is not up and running."
      exit 1
  fi
}

exitIfComposerPackageIsNotInstalled () {
  exitIfPhpContainerIsNotRunning
  if ! composerPackageIsInstalled "$1"; then
    echo "Package $1 is not installed."
    exit 1
  fi
}

declare -a targets
declare -a commands
commandCounter=0

addCommandForTarget () {
  ((commandCounter++))
  targets[$commandCounter]=$1
  commands[$commandCounter]=$2
}

case "$1" in
  # Assets
  run-dev)
    addCommandForTarget container "npm run dev" ;;
  run-prod)
    addCommandForTarget container "npm run prod" ;;
  watch)
    addCommandForTarget container "npm run watch" ;;

  # Composer
  install)
    addCommandForTarget container "composer install" ;;
  install-dry)
    addCommandForTarget container "composer install --dry-run" ;;
  outdated)
    addCommandForTarget container "composer outdated" ;;
  update)
    addCommandForTarget container "composer update" ;;
  update-dry)
    addCommandForTarget container "composer update --dry-run" ;;

  # Database
  fresh|refresh)
    addCommandForTarget container "php artisan migrate:fresh" ;;
  fresh-seed)
    addCommandForTarget container "php artisan migrate:fresh"
    addCommandForTarget container "php artisan db:seed" ;;
  migrate)
    addCommandForTarget container "php artisan migrate" ;;
  seed)
    addCommandForTarget container "php artisan db:seed" ;;

  # Docker
  build|rebuild)
    addCommandForTarget host "docker-compose build --no-cache" ;;
  down)
    addCommandForTarget host "docker-compose down" ;;
  ps)
    addCommandForTarget host "docker-compose ps --all" ;;
  restart)
    addCommandForTarget host "docker-compose restart" ;;
  restart-down)
    addCommandForTarget host "docker-compose down"
    addCommandForTarget host "docker-compose up --detach" ;;
  stop)
    addCommandForTarget host "docker-compose stop" ;;
  up)
    addCommandForTarget hots "docker-compose up --detach" ;;

  # Inspection
  coverage)
    addCommandForTarget container "phpunit --coverage-text" ;;
  cs|fixer)
    addCommandForTarget container "/usr/local/bin/php-cs-fixer fix --dry-run --diff" ;;
  larastan)
    exitIfComposerPackageIsNotInstalled nunomaduro/larastan
    addCommandForTarget container "./vendor/bin/phpstan analyse" ;;

  # Logging
  log|logs)
    addCommandForTarget host "docker-compose logs --follow --timestamps --tail=100 $([[ $# -gt 1 ]] && echo "$2")" ;;

  # Optimization
  cache|clear)
    addCommandForTarget container "php artisan event:clear"
    addCommandForTarget container "php artisan optimize:clear" ;;
  ide-helper)
    exitIfComposerPackageIsNotInstalled barryvdh/laravel-ide-helper
    addCommandForTarget container "php artisan clear-compiled"
    addCommandForTarget container "php artisan ide-helper:generate --helpers"
    addCommandForTarget container "php artisan ide-helper:models --nowrite"
    addCommandForTarget container "php artisan ide-helper:meta" ;;

  # Routes
  routes)
    addCommandForTarget container "php artisan route:list" ;;
  routes-get)
    addCommandForTarget container "php artisan route:list --method=GET" ;;
  routes-name)
    addCommandForTarget container "php artisan route:list --name=$2" ;;
  routes-post)
    addCommandForTarget container "php artisan route:list --method=POST" ;;
  routes-path)
    addCommandForTarget container "php artisan route:list --path=$2" ;;

  # Testing for Laravel version < 7
  feature6)
    addCommandForTarget container "phpunit --testsuite Feature$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;
  unit6)
    addCommandForTarget container "phpunit --testsuite Unit$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;
  test6|tests6)
    addCommandForTarget container "phpunit$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;

  # Testing for Laravel >= 7
  feature)
    addCommandForTarget container "php artisan test --testsuite Feature$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;
  unit)
    addCommandForTarget container "php artisan test --testsuite Unit$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;
  test|tests)
    addCommandForTarget container "php artisan test$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;

  # Other
  artisan)
    addCommandForTarget container "php artisan list" ;;
  bash|enter)
    addCommandForTarget container "bash" ;;
  *)
    addCommandForTarget container "${*}" ;;
esac

# Loop over the commands
for (( i=1; i<=${#commands[@]}; i++ ))
do
  # Run command on right target
  if [ "${targets[$i]}" == "container" ]; then
    # Check if PHP container is up and running
    exitIfPhpContainerIsNotRunning
    # Display actual command
    printf "${CATEGORY}Executing: ${DEFAULT}docker exec -it ${CONTAINER_PREFIX}-php %s\n" "${commands[$i]}"
    # Execute command
    docker exec -it "${CONTAINER_PREFIX}"-php ${commands[$i]}
  else
    # Display actual command
    printf "${CATEGORY}Executing: ${DEFAULT}%s\n" "${commands[$i]}"
    # Execute command
    ${commands[$i]}
  fi
done

exit 0
