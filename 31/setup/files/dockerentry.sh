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

mkdir -p /home/mythtv/Desktop/

# Create Mythtv users
echo "Update mythtv user ids and groups"
echo "USER_ID=$USER_ID"
echo "GROUP_ID=$GROUP_ID"

USERID=${USER_ID:-99}
GROUPID=${GROUP_ID:-100}

echo "USERID=$USERID"
echo "GROUPID=$GROUPID"
groupmod -g $GROUPID users
usermod -u $USERID mythtv
usermod -g $GROUPID mythtv
usermod -d /home/mythtv mythtv
usermod -a -G mythtv,users,adm,sudo mythtv
chown -R mythtv:mythtv /home/mythtv/

# set permissions for files/folders
chown -R mythtv:users /var/lib/mythtv /var/log/mythtv

# Fix the config
if [ -f "/var/lib/mythtv/.mythtv/config.xml" ]; then
  echo "Copying config file that was set in home"
  cp /var/lib/mythtv/.mythtv/config.xml /root/config.xml
else
  echo "Setting config from environment variables"
  cat << EOF > /root/config.xml
<Configuration>
  <Database>
    <PingHost>1</PingHost>
    <Host>${DATABASE_HOST}</Host>
    <UserName>${DATABASE_USER}</UserName>
    <Password>${DATABASE_PWD}</Password>
    <DatabaseName>${DATABASE_NAME}</DatabaseName>
    <Port>${DATABASE_PORT}</Port>
  </Database>
  <WakeOnLAN>
    <Enabled>0</Enabled>
    <SQLReconnectWaitTime>0</SQLReconnectWaitTime>
    <SQLConnectRetry>5</SQLConnectRetry>
    <Command>echo 'WOLsqlServerCommand not set'</Command>
  </WakeOnLAN>
</Configuration>
EOF
fi
mkdir -p /home/mythtv/.mythtv
cp /root/config.xml /root/.mythtv/config.xml
cp /root/config.xml /usr/share/mythtv/config.xml
cp /root/config.xml /etc/mythtv/config.xml
cp /root/config.xml /home/mythtv/.mythtv/config.xml

for f in /var/lib/mythtv/.mythtv/*.xmltv; do
    [ -e "$f" ] && echo "Copying XMLTV config file that was set in home" && 
    cp /var/lib/mythtv/.mythtv/*.xmltv /home/mythtv/.mythtv/ &&
    cp /home/mythtv/.mythtv/*.xmltv /root/.mythtv/
    break
done

# Prepare X
if [ -f "/home/mythtv/.Xauthority" ]; then
  echo ".Xauthority file appears to in place"
else
  touch /home/mythtv/.Xauthority
fi

if [ ! -f "/home/mythtv/Desktop/hdhr.desktop" ]; then
  cp /usr/share/applications/hdhr.desktop /home/mythtv/Desktop/hdhr.desktop
  chmod +x /home/mythtv/Desktop/hdhr.desktop
else
  echo "HDHomeRun Config is set"
fi

if [ ! -f "/home/mythtv/Desktop/mythtv-setup.desktop" ]; then
  cp /root/mythtv-setup.desktop /home/mythtv/Desktop/mythtv-setup.desktop
  chmod +x /home/mythtv/Desktop/mythtv-setup.desktop
else
  echo "setup desktop icon is set"
fi

# check folders
if [ -d "/var/lib/mythtv/banners" ]; then
  echo "mythtv folders appear to be set"
else
  mkdir -p /var/lib/mythtv/banners  /var/lib/mythtv/coverart  /var/lib/mythtv/db_backups  /var/lib/mythtv/fanart  /var/lib/mythtv/livetv  /var/lib/mythtv/recordings  /var/lib/mythtv/screenshots  /var/lib/mythtv/streaming  /var/lib/mythtv/trailers  /var/lib/mythtv/videos
fi

chown -R mythtv:users /var/lib/mythtv/banners  /var/lib/mythtv/coverart  /var/lib/mythtv/db_backups  /var/lib/mythtv/fanart  /var/lib/mythtv/livetv  /var/lib/mythtv/recordings  /var/lib/mythtv/screenshots  /var/lib/mythtv/streaming  /var/lib/mythtv/trailers  /var/lib/mythtv/videos

#Does the MythTV Database Exist?
if [ "xpwd" != "x$DATABASE_ROOT_PWD" ]; then
	echo "Check if mythconverg database exists"
	output=$(mysql -s -N -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u ${DATABASE_ROOT} -p${DATABASE_ROOT_PWD} -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '${DATABASE_NAME}'" information_schema)
	echo "  Query result = ${output}"
	if [[ -z "${output}" ]]; then
	  echo "Creating database(s)."
	  mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u ${DATABASE_ROOT} -p${DATABASE_ROOT_PWD} -e "CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME}"
	  mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u ${DATABASE_ROOT} -p${DATABASE_ROOT_PWD} -e "CREATE USER '${DATABASE_USER}' IDENTIFIED BY '${DATABASE_PASS}'"
	  mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u ${DATABASE_ROOT} -p${DATABASE_ROOT_PWD} -e "GRANT ALL ON ${DATABASE_NAME}.* TO '${DATABASE_USER}' IDENTIFIED BY '${DATABASE_PASS}'"
	  mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u ${DATABASE_ROOT} -p${DATABASE_ROOT_PWD} -e "GRANT CREATE TEMPORARY TABLES ON ${DATABASE_NAME}.* TO '${DATABASE_USER}' IDENTIFIED BY '${DATABASE_PASS}'"
	  mysql -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u ${DATABASE_ROOT} -p${DATABASE_ROOT_PWD} -e "ALTER DATABASE ${DATABASE_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"
	else
	  echo "Database already exists"
	fi
fi

# Bring up VNC
x11vnc -storepasswd $VNC_PASS /root/.vnc/passwd

/usr/bin/supervisord -c /root/supervisor-files/vnc-supervisord.conf -n
