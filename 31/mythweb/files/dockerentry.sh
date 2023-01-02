#!/bin/bash

# Set timezone
echo "Set correct timezone"
echo "TZ = $TZ"
if [[ $(cat /etc/timezone) != $TZ ]] ; then
  echo "Update timezone"
  echo $TZ > /etc/timezone && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
else
  echo "Timezone is already correct"
fi

# Fix the config
echo "Setting database configuration"
sed -i "s/setenv db_server.*/setenv db_server ${DATABASE_HOST}/" /etc/apache2/sites-available/mythweb.conf
sed -i "s/setenv db_name.*/setenv db_name ${DATABASE_NAME}/" /etc/apache2/sites-available/mythweb.conf
sed -i "s/setenv db_login.*/setenv db_login ${DATABASE_USER}/" /etc/apache2/sites-available/mythweb.conf
sed -i "s/setenv db_password.*/setenv db_password ${DATABASE_PWD}/" /etc/apache2/sites-available/mythweb.conf

echo "starting mythweb"
/usr/sbin/apache2ctl -D FOREGROUND