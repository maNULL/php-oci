FROM composer:latest AS composer

FROM php:7.4.1-fpm-alpine3.11

LABEL maintainer="John Komarov <komarov.j@gmail.com>"

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY ./instantclient/11.2/instantclient-basiclite-linux.x64-11.2.0.4.0.zip \
     ./instantclient/11.2/instantclient-sdk-linux.x64-11.2.0.4.0.zip \
     ./instantclient/11.2/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip \
     /opt/oracle/

ENV LD_LIBRARY_PATH /opt/oracle/instantclient_11_2:${LD_LIBRARY_PATH}

RUN unzip /opt/oracle/instantclient-basiclite-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
    \
    && ln -s /opt/oracle/instantclient_11_2/libclntsh.so.11.1 /opt/oracle/instantclient_11_2/libclntsh.so \
    && ln -s /opt/oracle/instantclient_11_2/libocci.so.11.1 /opt/oracle/instantclient_11_2/libocci.so \
    && ln -s /opt/oracle/instantclient_11_2/sqlplus /usr/bin/sqlplus \
    && rm -f /opt/oracle/*.zip \
    \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache libnsl libaio-dev icu-dev \
    && ln -s /usr/lib/libnsl.so.2 /usr/lib/libnsl.so.1 \
    \
    && pecl install xdebug-2.9.0 \
    && pecl install apcu-5.1.18 \
    \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient_11_2/ \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_11_2,11.2 \
    && docker-php-ext-configure opcache --enable-opcache \
    \
    && docker-php-ext-install -j$(nproc) oci8 pdo_oci opcache intl \
    \
    && docker-php-ext-enable xdebug apcu \
    \
    && apk del .phpize-deps
