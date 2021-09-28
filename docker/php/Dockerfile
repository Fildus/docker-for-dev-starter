FROM php:8-fpm

WORKDIR /application

RUN apt-get -y update &&\
    apt-get -y upgrade &&\
    apt-get install -y libicu-dev &&\
    docker-php-ext-install intl pdo pdo_mysql

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

RUN apt-get install -y zip