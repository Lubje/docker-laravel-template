#!/bin/bash

# Get container-prefix from the docker-compose .env file
COMPOSE_PROJECT_NAME="$(grep COMPOSE_PROJECT_NAME .env | xargs)"
IFS='=' read -ra COMPOSE_PROJECT_NAME <<< "$COMPOSE_PROJECT_NAME"
CONTAINER_PREFIX="${COMPOSE_PROJECT_NAME[1]}"

# Set output colors and spacing
DEFAULT="\033[0m"
CATEGORY="\033[33m"
COMMAND="\033[32m"
SPACING="   "

if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "commands" ]; then
  printf "${DEFAULT}Use ./develop.sh ${COMMAND}<command>${DEFAULT}\n\n"

  printf "${DEFAULT}Available ${COMMAND}commands${DEFAULT} per ${CATEGORY}category${DEFAULT}:\n"

  printf "${CATEGORY} Composer\n"
  printf "${COMMAND}  install      ${SPACING}${DEFAULT}Install composer dependencies\n"
  printf "${COMMAND}  install-dry  ${SPACING}${DEFAULT}Fake install composer dependencies\n"
  printf "${COMMAND}  outdated     ${SPACING}${DEFAULT}Show outdated composer dependencies\n"
  printf "${COMMAND}  update       ${SPACING}${DEFAULT}Update composer dependencies\n"
  printf "${COMMAND}  update-dry   ${SPACING}${DEFAULT}Fake update composer dependencies\n"

  printf "${CATEGORY} Database\n"
  printf "${COMMAND}  fresh|refresh${SPACING}${DEFAULT}Drop all tables and run all migrations\n"
  printf "${COMMAND}  fresh-seed   ${SPACING}${DEFAULT}Drop all tables and run all migrations and seeders\n"
  printf "${COMMAND}  migrate      ${SPACING}${DEFAULT}Run the database migrations\n"
  printf "${COMMAND}  seed         ${SPACING}${DEFAULT}Seed the database with records\n"

  printf "${CATEGORY} Docker\n"
  printf "${COMMAND}  build|rebuild${SPACING}${DEFAULT}Build the images without cache\n"
  printf "${COMMAND}  down         ${SPACING}${DEFAULT}Stop and remove the containers\n"
  printf "${COMMAND}  ps           ${SPACING}${DEFAULT}List the containers\n"
  printf "${COMMAND}  restart      ${SPACING}${DEFAULT}Restart the containers\n"
  printf "${COMMAND}  restart-down ${SPACING}${DEFAULT}Restart the containers using down\n"
  printf "${COMMAND}  stop         ${SPACING}${DEFAULT}Stop the containers\n"
  printf "${COMMAND}  up           ${SPACING}${DEFAULT}Start the containers\n"

  printf "${CATEGORY} Inspection\n"
  printf "${COMMAND}  coverage     ${SPACING}${DEFAULT}Run PHPunit code coverage analysis with PCOV\n"
  printf "${COMMAND}  cs           ${SPACING}${DEFAULT}Show codestyle issues with PHP-CS-Fixer\n"
  printf "${COMMAND}  fix          ${SPACING}${DEFAULT}Fix codestyle issues with PHP-CS-Fixer\n"
  printf "${COMMAND}  stan         ${SPACING}${DEFAULT}Run static analysis with larastan\n"

  printf "${CATEGORY} Logging\n"
  printf "${COMMAND}  log|logs     ${SPACING}${DEFAULT}Tail logs, use optional 1st argument to specify a service (mysql,nginx,php,redis)\n"

  printf "${CATEGORY} Npm\n"
  printf "${COMMAND}  n-install    ${SPACING}${DEFAULT}Install npm dependencies\n"
  printf "${COMMAND}  n-outdated   ${SPACING}${DEFAULT}Show outdated npm dependencies\n"
  printf "${COMMAND}  n-update     ${SPACING}${DEFAULT}Update npm dependencies\n"
  printf "${COMMAND}  run-dev      ${SPACING}${DEFAULT}Compile assets for development\n"
  printf "${COMMAND}  run-prod     ${SPACING}${DEFAULT}Compile assets for production\n"
  printf "${COMMAND}  watch        ${SPACING}${DEFAULT}Run scripts from package.json when files change\n"

  printf "${CATEGORY} Optimization\n"
  printf "${COMMAND}  cache|clear  ${SPACING}${DEFAULT}Clear all the cache\n"
  printf "${COMMAND}  ide-helper   ${SPACING}${DEFAULT}Create IDE autocompletion files\n"

  printf "${CATEGORY} Routes\n"
  printf "${COMMAND}  routes       ${SPACING}${DEFAULT}List all routes\n"
  printf "${COMMAND}  routes-method${SPACING}${DEFAULT}List routes filtered by method use 1st argument as filter-value\n"
  printf "${COMMAND}  routes-name  ${SPACING}${DEFAULT}List routes filtered by name, use 1st argument as filter-value\n"
  printf "${COMMAND}  routes-path  ${SPACING}${DEFAULT}List routes filtered by path, use 1st argument as filter-value\n"

  printf "${CATEGORY} Testing\n"
  printf "${COMMAND}  feature      ${SPACING}${DEFAULT}Run feature tests, use optional 1st argument as filter-value\n"
  printf "${COMMAND}  test|tests   ${SPACING}${DEFAULT}Run all tests, use optional 1st argument as filter-value\n"
  printf "${COMMAND}  unit         ${SPACING}${DEFAULT}Run unit tests, use optional 1st argument as filter-value\n"

  printf "${CATEGORY} Other\n"
  printf "${COMMAND}  art          ${SPACING}${DEFAULT}Run artisan commands on the php container\n"
  printf "${COMMAND}  bash|enter   ${SPACING}${DEFAULT}Run bash in the php container\n"
  printf "${COMMAND}  *            ${SPACING}${DEFAULT}Anything else will be run in the php container, e.g. \"php -m | grep mysql\"\n"
  exit 0
fi

# Exit if the Docker daemon is not running
dockerResponse=$(docker info --format '{{json .}}')
if echo "${dockerResponse}" | grep -q "Is the docker daemon running?"; then
  echo "Docker is not running."
  exit 1
fi

composerPackageIsInstalled () {
  docker exec "${CONTAINER_PREFIX}"-php composer show | grep "$1" > /dev/null
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

getLaravelMainVersion () {
  echo "$(docker exec "${CONTAINER_PREFIX}"-php php artisan --version | awk '{print $3}' | cut -d . -f1)"
}

getTestBaseCommandForLaravelMainVersion () {
  if [[ $(getLaravelMainVersion) -ge 7 ]]; then
    echo "php artisan test"
  else
    echo "phpunit"
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
    addCommandForTarget container "phpunit --coverage-text --printer PHPUnit\TextUI\ResultPrinter" ;;
  cs)
    exitIfComposerPackageIsNotInstalled friendsofphp/php-cs-fixer
    addCommandForTarget container "php-cs-fixer fix --dry-run --diff" ;;
  fix)
    exitIfComposerPackageIsNotInstalled friendsofphp/php-cs-fixer
    addCommandForTarget container "php-cs-fixer fix" ;;
  stan)
    exitIfComposerPackageIsNotInstalled nunomaduro/larastan
    addCommandForTarget container "phpstan analyse" ;;

  # Logging
  log|logs)
    addCommandForTarget host "docker-compose logs --follow --timestamps --tail=100 $([[ $# -gt 1 ]] && echo "$2")" ;;

  # Npm
  n-install)
    addCommandForTarget container "npm install" ;;
  n-outdated)
    addCommandForTarget container "npm outdated" ;;
  n-update)
    addCommandForTarget container "npm update" ;;
  run-dev)
    addCommandForTarget container "npm run dev" ;;
  run-prod)
    addCommandForTarget container "npm run prod" ;;
  watch)
    addCommandForTarget container "npm run watch" ;;

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
  routes-method)
    addCommandForTarget container "php artisan route:list --method=$2" ;;
  routes-name)
    addCommandForTarget container "php artisan route:list --name=$2" ;;
  routes-path|routes-uri)
    addCommandForTarget container "php artisan route:list --path=$2" ;;

  # Testing
  feature)
    addCommandForTarget container "$(getTestBaseCommandForLaravelMainVersion) --testsuite Feature$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;
  unit)
    addCommandForTarget container "$(getTestBaseCommandForLaravelMainVersion) --testsuite Unit$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;
  test|tests)
    addCommandForTarget container "$(getTestBaseCommandForLaravelMainVersion)$([[ $# -gt 1 ]] && echo " --filter ${*:2}")" ;;

  # Other
  art)
    addCommandForTarget container "php artisan $([[ $# -gt 1 ]] && echo "${*:2}")" ;;
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
