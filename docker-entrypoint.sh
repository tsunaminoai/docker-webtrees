#!/bin/sh

NGINX_CONFIG_FILE=/etc/nginx/nginx.conf
PHP_CONFIG=/var/www/html/data/config.ini.php

# Update server_name in nginx config as webtrees relies on it for redirections
sed -i "s/server_name localhost;/server_name ${SERVER_NAME};/" ${NGINX_CONFIG_FILE}

# Update server name in php config file to support v2 per https://webtrees.net/upgrade/2.0/
BASE_URL_UPDATE=${BASE_URL:="http://${SERVER_NAME}"}
BASE_URL_CURRENT=`grep -e '^base_url=' ${PHP_CONFIG} | sed 's/^base_url=\(.*\);/\1/'`
if [ "${BASE_URL_UPDATE}" != "${BASE_URL_CURRENT}" ]; then
  if [ "${BASE_URL_CURRENT}" == '' ]; then
    echo "base_url=${BASE_URL_UPDATE};" >> ${PHP_CONFIG}
  else
    BASE_URL_ESCAPED=`echo ${BASE_URL_UPDATE}|sed -e 's/\//\\\\\//g'`
    sed -i "s/base_url=.*/base_url=${BASE_URL_ESCAPED}/" ${PHP_CONFIG}
  fi
fi

# If the data directory is created as a mount point, it will not have the proper permissions or default content. Setup the data directory.
cp -r /var/www/html/data.bak/. /var/www/html/data
chown www-data /var/www/html/data
chmod g+w /var/www/html/data


# Pull data directory content from git if data directory is empty


# Start supervisord and services
/usr/bin/supervisord -c /etc/supervisord.conf

exec "$@"
