FROM celerative/nginx-php-fpm:7.1

MAINTAINER Celerative <bruno.cascio@celerative.com>

ARG APP_PATH=/var/www/html
ARG INSTALL_MONGO=false
ARG INSTALL_REDIS=false
ARG INSTALL_MYSQL=true

ENV APP_PATH $APP_PATH

WORKDIR $APP_PATH

#
# install required deps
#
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libpng12-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
  # install composer
  && curl -sS "https://getcomposer.org/installer" | php \
  && mv composer.phar /bin/composer \
  # install mcrypt
  && docker-php-ext-install mcrypt \
  # Install the PHP gd library
  && docker-php-ext-configure gd \
    --enable-gd-native-ttf \
    --with-jpeg-dir=/usr/lib \
    --with-freetype-dir=/usr/include/freetype2 \
  && docker-php-ext-install gd \
  #
  # clean packages
  #
  && rm -rf /var/lib/apt/lists/*

#
# install additional packages
#
RUN (($INSTALL_MONGO)) && \
  ( \
    pecl install mongodb \
    && docker-php-ext-enable mongodb \
  ) || echo "Skipped MongoDB installation." \
  # Redis Package
  && (($INSTALL_REDIS)) && \
  ( \
    pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis \
  ) || echo "Skipped Redis installation." \
  # MYSQL Package
  && (($INSTALL_MYSQL)) && \
  ( \
    docker-php-ext-install pdo_mysql \
  ) || echo "Skipped MYSQLi installation."


RUN composer config --global repo.packagist composer https://packagist.org \
  && composer global require hirak/prestissimo --verbose \
  && composer clearcache

ONBUILD COPY composer.* $APP_PATH/

ONBUILD RUN test -f "${APP_PATH}/composer.json" \
  && composer install \
    --no-suggest \
    --no-scripts \
    --profile \
    --no-autoloader \
  && composer clearcache \
  || echo "==> Composer json not found. Skipping. <=="

ONBUILD COPY . $APP_PATH/

ONBUILD RUN test -f "${APP_PATH}/composer.json" \
  && composer dump-autoload \
  && composer run-script post-install-cmd \
  || echo "==> Composer json not found. Skipping. <=="

ONBUILD RUN chown www-data:www-data -R $APP_PATH/