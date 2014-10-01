#!/bin/bash

VAGRANT_ROOT=/vagrant

# If you want to restore an SQL dump file so as to have
# a pre-configured JSS, set JSS_DUMPFILE to a path that
# contains a dump.
# You can create a dump file by doing the following once
# you have a configuration you want in the Vagrant VM:
#
# 1. vagrant ssh
# 2. sudo mysqldump -u root --password=JAMF \
#      jamfsoftware > /vagrant/data/jss_data.sql
# 3. Copy the dump file back to your Vagrant project
#    directory if necessary, for example if using a
#    provider where the synced folder is not bi-directional.
JSS_DUMPFILE="${VAGRANT_ROOT}/data/jss_data.sql"

# Auto-configuration of JSS URL
#
# JSS_URL_USE_INTERFACE: set this to an interface name,
# ie. 'eth0' and the JSS URL will be set to
# the machine's IP address and port 8443.
# Leave it undefined if you want to configure the JSS
# URL yourself via JSS_FULL_URL, which takes precedence.

# JSS_FULL_URL should contain the
# full URL, ie. 'https://jss.example.com:8443'.
# If either are omitted, then no auto-configuration
# will be attempted and the value will remain whatever
# it was if an SQL dump was restored.
JSS_URL_CONFIGURE_FROM_INTERFACE=
JSS_FULL_URL="https://jss-msa:8443"

timedatectl set-timezone America/Montreal

# run updates, avoid upgrading grubby packages
apt-get update
apt-mark hold grub-common grub-pc grub-pc-bin grub2-common
# speedup
apt-get -y upgrade

# preset the root pass so we don't get an interactive prompt
debconf-set-selections <<< 'mysql-server mysql-server/root_password password JAMF'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password JAMF'

# install our dependencies
apt-get -y install mysql-server openjdk-6-jdk tomcat7 unzip

# -- MySQL
# initial database and user
mysql -u root --password=JAMF < "${VAGRANT_ROOT}/data/jamfsoftware.sql"
# restore from our dump file if one exists
if [ -e "${JSS_DUMPFILE}" ]; then
    sudo mysql -u root --password=JAMF -D jamfsoftware < "${JSS_DUMPFILE}"
fi


# -- Webapp
/etc/init.d/tomcat7 stop

# move out the default webapp
mv /var/lib/tomcat7/webapps/ROOT /var/lib/tomcat7/webapps/TOMCAT

# unpack the warfile ourselves and set a sane logging directory
unzip "${VAGRANT_ROOT}/jss-app/ROOT.war" -d /var/lib/tomcat7/webapps/ROOT
sed \
  -i.bak \
  "s/\/Library\/JSS\/Logs/\/var\/log\/jss/g" \
  /var/lib/tomcat7/webapps/ROOT/WEB-INF/classes/log4j.properties
# create said logging directory
mkdir /var/log/jss
chown tomcat7 /var/log/jss

# make a new key w/ passphrase
keytool \
-genkey \
-alias tomcat \
-keyalg RSA \
-keypass "JAMFSOFTWARE" \
-storepass "JAMFSOFTWARE" \
-dname "CN=jss.example.com, OU=JAMFSW, O=JAMF Software, L=Minneapolis, ST=MN, C=US" \
-keystore /etc/tomcat7/keystore \
-validity 1000

# move in the new server config
cp /etc/tomcat7/server.xml /etc/tomcat7/server.xml.bak
cp "${VAGRANT_ROOT}/data/server.xml" /etc/tomcat7/server.xml

# copy in our custom default env if we have one
tomcat_default="${VAGRANT_ROOT}/data/tomcat7-default"
if [ -e "${tomcat_default}" ]; then
  cp "${tomcat_default}" /etc/default/tomcat7
fi

/etc/init.d/tomcat7 start

# Janky auto-config of the JSS URL
# - writing to SQL directly, tested only with 9.32 and 9.4
if [ -n "${JSS_URL_CONFIGURE_FROM_INTERFACE}" ]; then
  IP=$(/sbin/ifconfig "${JSS_URL_CONFIGURE_FROM_INTERFACE}" | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
  autoconfig=1
  jss_url="https://${IP}:8443"
fi

if [ -n "${JSS_FULL_URL}" ]; then
  autoconfig=1
  jss_url="${JSS_FULL_URL}"
fi

if [ ! -e "${JSS_DUMPFILE}" ]; then
    autoconfig=
    echo "Ignoring JSS URL auto-config, no dump file was present."
fi


if [ -n "${autoconfig}" ] && [ -e "${JSS_DUMPFILE}" ]; then
  echo "Attempting to auto-configure JSS URL to: ${jss_url}"
  mysql -u root --password=JAMF jamfsoftware << EOF
  LOCK TABLES jss_server_url WRITE;
  INSERT INTO jss_server_url VALUES ('${jss_url}','');
  UNLOCK TABLES;
EOF
fi
