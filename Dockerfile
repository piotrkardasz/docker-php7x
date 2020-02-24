#https://github.com/docker-library/php/blob/affbdaf1386876560e287cd7708fafe2a4d246eb/7.3/buster/fpm/Dockerfile
FROM php:7.4-fpm

#https://github.com/docker-library/docs/blob/master/php/README.md#pecl-extensions
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        nano \
        zlib1g-dev \
        libxml2-dev \
        libicu-dev \
        g++ \
        net-tools

RUN pecl install redis-5.1.1 \
	&& pecl install xdebug-2.9.2 \
	&& docker-php-ext-enable redis xdebug \
	&& docker-php-ext-configure intl \
	&& docker-php-ext-install -j$(nproc) intl
RUN docker-php-ext-configure soap \
    && docker-php-ext-install -j$(nproc) soap
RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

COPY basics.ini  "$PHP_INI_DIR/conf.d/"
COPY xdebug.ini  "$PHP_INI_DIR/conf.d/"
COPY timezone.ini  "$PHP_INI_DIR/conf.d/"

RUN echo "$(curl -sS https://composer.github.io/installer.sig) -" > composer-setup.php.sig \
        && curl -sS https://getcomposer.org/installer | tee composer-setup.php | sha384sum -c composer-setup.php.sig \
        && php composer-setup.php && rm composer-setup.php* \
        && chmod +x composer.phar && mv composer.phar /usr/bin/composer

#Change port to 9001
RUN set -eux; \
	cd /usr/local/etc; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9001'; \
	} | tee php-fpm.d/zz-docker.conf

CMD ["php-fpm"]

EXPOSE 9001
