
FROM php:7.3-apache

# Install packages
RUN apt-get update && apt-get install -y \
    vim \
    git \
    cron \
    zip \
    curl \
    supervisor \
    unzip \
    redis \
    libzip-dev \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    libwebp-dev \
    libjpeg62-turbo-dev \
    mariadb-client \
    g++


RUN docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

ENV APACHE_CONF_DIR=/etc/apache2

# Apache configuration
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN a2enmod headers
RUN sed -ri -e 's/^([ \t]*)(<\/VirtualHost>)/\1\tHeader set Access-Control-Allow-Origin "*"\n\1\2/g' /etc/apache2/sites-available/*.conf

RUN a2enmod rewrite headers

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs


# Common PHP Extensions
RUN docker-php-ext-install \
    bz2 \
    exif \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    zip \
    pdo_mysql

# Ensure PHP logs are captured by the container
ENV LOG_CHANNEL=stderr


# Copy code and run composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer


RUN npm install  -g pm2  && npm install -g laravel-echo-server

EXPOSE 80 443  6001 

RUN mkdir -p /etc/supervisor/conf.d

ADD master_apache.ini  /etc/supervisor/conf.d
RUN echo user=root >>  /etc/supervisor/supervisord.conf


RUN echo '* * * * * /usr/local/bin/php -q -f /var/www/html/artisan schedule:run >> /dev/null 2>&1' >> /var/spool/cron/crontabs/root

RUN chmod 600 /var/spool/cron/crontabs/root

# The default apache run command
#CMD ["apache2-foreground"]
#CMD ["/usr/bin/supervisord"]
CMD supervisord -n -c /etc/supervisor/conf.d/master_apache.ini


