FROM thecodingmachine/php:7.4-v3-fpm-node12

RUN curl -L https://cs.symfony.com/download/php-cs-fixer-v2.phar -o php-cs-fixer \
    && sudo chmod a+x php-cs-fixer \
    && sudo mv php-cs-fixer /usr/local/bin/php-cs-fixer

COPY --chown=docker:docker /src/ /var/www/html/
