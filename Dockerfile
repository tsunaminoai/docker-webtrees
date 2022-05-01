FROM php:8.1.5-fpm-alpine

ENV WEBTREES_VERSION 2.1.1

RUN set -e \
    && apk add --no-cache \
       supervisor \
       nginx \
       # GD
       freetype libpng libjpeg-turbo icu-dev libzip-dev \
    && apk add --no-cache --virtual .build-deps \
       # For pulling archive over https
       ca-certificates \
       openssl \
       # For GD (creating thumbnails inside webtrees)
       libpng-dev libjpeg-turbo-dev freetype-dev \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install \
       gd \
       pdo \
       mysqli \
       pdo_mysql \
       exif \
       intl \
       zip \
    && wget https://github.com/fisharebest/webtrees/releases/download/$WEBTREES_VERSION/webtrees-$WEBTREES_VERSION.zip \
    && unzip webtrees-$WEBTREES_VERSION.zip \
    && rm webtrees-$WEBTREES_VERSION.zip \
    && mv webtrees/* . \
    && rmdir webtrees \
    && apk del .build-deps \
    && cp -r /var/www/html/data /var/www/html/data.bak \
    && chmod 0755 /var/lib/nginx \
    && chown -R www-data /var/www/html \
    && chmod -R g-w /var/www/html*

COPY nginx.conf /etc/nginx/
COPY supervisord.conf /etc/
COPY docker-entrypoint.sh /usr/local/bin/

RUN set -ex \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chown www-data -R /var/lib/nginx/tmp/ \
    && chmod g+rwx -R /var/lib/nginx/tmp/

VOLUME /var/www/html/data

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
