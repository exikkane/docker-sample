FROM php:8.2.29-apache

RUN apt-get -y update
RUN apt-get -y install libzip-dev zip unzip libsodium-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-install pdo_mysql sodium zip sockets mysqli
RUN pecl install redis && docker-php-ext-enable redis
RUN a2enmod rewrite
RUN apt-get upgrade -y
RUN apt-get clean

COPY ./docker/apache/ssl/selfsigned.crt /etc/ssl/certs/
COPY ./docker/apache/ssl/selfsigned.key /etc/ssl/private/
COPY ./docker/apache/vhost-ssl.conf /etc/apache2/sites-available/
RUN a2ensite default-ssl
RUN a2enmod ssl
RUN a2enmod headers

WORKDIR /var/www/html

# INSTALL AND UPDATE COMPOSER
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN composer self-update