#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export TERM=xterm-256color

CLOUD_HOME=/home/coronium
CLOUD_LIB=/usr/local/coronium

TERRAFORM_SUPPORT=/home/coronium/support

NGINX_LIB=/usr/local/openresty

# Make init directories
dir=(\
"/home/coronium/support" \
"/data/db" \
"/var/lib/mongodb" \
"/var/log/mysql" \
"/var/run/mysqld" \
"/usr/share/mysql" \
"./tmp");

for d in "${dir[@]}";
do
  mkdir -p $d
done

#download cloud pack
cd $TERRAFORM_SUPPORT

#RG Use My Local Copy
#wget https://s3.amazonaws.com/coronium-cloud/coronium-cloud.tar.gz
wget https://github.com/roaminggamer/CoroniumCloud/raw/master/server/coronium-cloud.tar.gz
tar xzf coronium-cloud.tar.gz

tar xzf coronium-misc.tar.gz
mv misc/* .

rm -rf misc
#RG Keep DL 
#rm coronium-cloud.tar.gz
rm coronium-misc.tar.gz

newusers $TERRAFORM_SUPPORT/coronium_user
adduser coronium sudo

#Install Server Conponents
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list

apt-get update -y

apt-get install -y \
  apache2 \
  apache2-utils \
  figlet \
  git \
  mariadb-server \
  mariadb-client \
  mongodb-org \
  perl \
  php5 \
  php5-mysql \
  php5-mcrypt \
  php5-gd \
  php5-mongo \
  postfix \
  uuid \
  unzip \
  zip

#Expand Core

#Nginx/Lua
tar zxf $TERRAFORM_SUPPORT/coronium-openresty.tar.gz -C /usr/local/

# Coronium Core
tar zxf $TERRAFORM_SUPPORT/coronium-core.tar.gz -C /usr/local/
chown coronium:coronium /usr/local/coronium/bin/sendEmail

# Coronium Home
tar zxf $TERRAFORM_SUPPORT/coronium-home.tar.gz -C /

cp -R $TERRAFORM_SUPPORT/usr/* /usr/.
cp -R $TERRAFORM_SUPPORT/etc/* /etc/.

mongo $TERRAFORM_SUPPORT/coronium_dbtoast_mg.js

#MySQL init
service mysql start
MYSQL=`which mysql`
$MYSQL -uroot < $TERRAFORM_SUPPORT/coronium_mysql.sql

#Link Dirs
cd $CLOUD_LIB/http
ln -s $CLOUD_HOME/php userphp
ln -s $CLOUD_HOME/files files

cd $CLOUD_LIB
ln -s $CLOUD_HOME/.tmp tmp
ln -s $CLOUD_HOME/tpl tpl

mv $TERRAFORM_SUPPORT/etc/update-motd.d/05-coronium /etc/update-motd.d/
mv $TERRAFORM_SUPPORT/etc/update-motd.d/10-help-text /etc/update-motd.d/
chmod 0755 /etc/update-motd.d/05-coronium
#
sed 's/PermitRootLogin yes/PermitRootLogin no/' -i /etc/ssh/sshd_config
sed 's/PrintMotd no/PrintMotd yes/' -i /etc/ssh/sshd_config
sed 's/PrintLastLog yes/PrintLastLog no/' -i /etc/ssh/sshd_config

#SuperChownd
chown -R root:root $CLOUD_LIB
chown coronium:coronium $CLOUD_LIB/conf/admin_auth
chown coronium:coronium $CLOUD_LIB/conf/api_key.lua

chown root:root /usr/bin/coronium-tools
chmod +x /usr/bin/coronium-tools

chown -R coronium:coronium $CLOUD_HOME

#nginx Lua cache
sed 's/lua_code_cache on/lua_code_cache off/' -i /usr/local/openresty/nginx/conf/nginx.conf
service coronium start

#reload apache config
# apache2ctl restart

#Clean
rm -rf $TERRAFORM_SUPPORT

#RG Skip Reboot
#reboot
