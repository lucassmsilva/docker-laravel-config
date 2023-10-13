FROM php:8.2-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid
ARG appname

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    tzdata

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install mbstring exif pcntl bcmath gd sockets

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Install redis
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

RUN apt-get update && apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libaio1 wget && apt-get clean autoclean && apt-get autoremove --yes &&  rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN apt-get install -y autoconf pkg-config libssl-dev git libzip-dev zlib1g-dev && \
    pecl install mongodb && docker-php-ext-enable mongodb

RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd pdo pdo_mysql zip

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/


RUN install-php-extensions zip

RUN echo "upload_max_filesize = 20M" >> /usr/local/etc/php/php.ini
RUN echo "post_max_size = 20M" >> /usr/local/etc/php/php.ini
RUN echo "max_execution_time = 0" >> /usr/local/etc/php/php.ini
RUN echo "max_input_time = 0" >> /usr/local/etc/php/php.ini
RUN echo "memory_limit = 1024M" >> /usr/local/etc/php/php.ini


RUN  chown -R $user:www-data .
RUN  find . -path "./node_modules" -prune -o -type f -exec chmod 664 {} \; -o -type d -exec chmod 775 {} \;

RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

WORKDIR /var/www

RUN composer create-project laravel/laravel $appname

USER $user


