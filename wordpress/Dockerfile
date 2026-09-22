ARG PHP_VERSION

FROM serversideup/php:${PHP_VERSION:?}-fpm-apache

ARG USER_ID
ARG GROUP_ID

ENV SSL_MODE="mixed"
ENV LOG_OUTPUT_LEVEL="warn"
ENV SHOW_WELCOME_MESSAGE="false"
ENV APACHE_DOCUMENT_ROOT=/var/www/html

USER root

RUN docker-php-serversideup-dep-install-debian mariadb-client

RUN curl -sSL -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN docker-php-serversideup-set-id www-data "${USER_ID}:${GROUP_ID}" \
    && docker-php-serversideup-set-file-permissions --owner "${USER_ID}:${GROUP_ID}" --service apache

COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/

USER www-data
