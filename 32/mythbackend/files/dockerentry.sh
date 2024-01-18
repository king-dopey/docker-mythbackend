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
usermod -a -G mythtv,users mythtv
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

if [ -d "/var/lib/mythtv/banners" ]; then
  echo "mythtv folders appear to be set"
else
  mkdir -p /var/lib/mythtv/banners  /var/lib/mythtv/coverart  /var/lib/mythtv/db_backups  /var/lib/mythtv/fanart  /var/lib/mythtv/livetv  /var/lib/mythtv/recordings  /var/lib/mythtv/screenshots  /var/lib/mythtv/streaming  /var/lib/mythtv/trailers  /var/lib/mythtv/videos
fi

chown -R mythtv:users /var/lib/mythtv/banners  /var/lib/mythtv/coverart  /var/lib/mythtv/db_backups  /var/lib/mythtv/fanart  /var/lib/mythtv/livetv  /var/lib/mythtv/recordings  /var/lib/mythtv/screenshots  /var/lib/mythtv/streaming  /var/lib/mythtv/trailers  /var/lib/mythtv/videos

#Bring up the backend
chown -R mythtv:users /var/log/mythtv

echo "Checking whether database(s) are ready"
until [ "$( mysqladmin -h ${DATABASE_HOST} -P ${DATABASE_PORT} -u${DATABASE_USER} -p${DATABASE_PWD} status 2>&1 >/dev/null | grep -ci error:)" = "0" ]
do
echo "waiting....."
sleep 2s
done
echo "start backend"
exec su - mythtv -c "/usr/bin/mythbackend --syslog local7"
