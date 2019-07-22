ARG NGINX_VERSION=1.17

FROM nginx:${NGINX_VERSION}

COPY /docker/nginx/conf.d/*.conf /etc/nginx/conf.d/
COPY /docker/nginx/h5bp/ /etc/nginx/h5bp/
COPY /docker/nginx/mime.types /etc/nginx/mime.types
COPY /docker/nginx/nginx.conf /etc/nginx/nginx.conf

COPY --chown=www-data:www-data /src/public /var/www/html/public

