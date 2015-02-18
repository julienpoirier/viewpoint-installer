#!/bin/bash -x

# Config
installDir=/data/bddpmon/viewpoint/viewpoint/
rpmDir=${installDir}thirdparties/
confDir=${installDir}config/
dataDir=/data/bddpmon/viewpoint/
logDir=/log/bddpmon/viewpoint/


service logstash stop
service syslog-ng stop
service elasticsearch stop
service mysql stop
service nginx stop
service glassfish stop
service rabbitmq-server stop
rm -fr ${logDir}
rm -fr ${installDir}/bin/glassfish3

# syslog-ng.i686
sudo yum -y install syslog-ng

# rabbitmq
sudo yum -y install ${rpmDir}rabbitmq-server-3.4.2-1.noarch.rpm

# Elasticsearch
sudo yum -y install ${rpmDir}elasticsearch-1.4.2.noarch.rpm

# Mysql
sudo rpm -e postfix-2.6.6-2.2.el6_1.x86_64
sudo rpm -e mysql-libs-5.1.71-1.el6.x86_64
sudo yum -y install ${rpmDir}MySQL-server-5.6.22-1.el6.x86_64.rpm
sudo yum -y install ${rpmDir}MySQL-client-5.6.22-1.el6.x86_64.rpm

# Global dir 
chmod 755 ${installDir}
mkdir ${installDir}/bin
mkdir -p ${installDir}/app/www
chown -R bddpmon:bddpmon ${installDir}

#############
# NGinx
#############
sudo yum -y install ${rpmDir}nginx-1.7.9-1.el6.ngx.x86_64.rpm

# Nginx config
cp -pr ${confDir}default.conf.template /etc/nginx/conf.d/default.conf

# Logs
mkdir -p ${logDir}nginx
chown nginx:bddpmon ${logDir}nginx

#################
# Elasticsearch #
#################

mkdir -p ${dataDir}/elasticsearch/data
mkdir -p ${dataDir}/elasticsearch/work
mkdir -p ${dataDir}/elasticsearch/plugins
mkdir -p ${logDir}/elasticsearch
chown -R elasticsearch:bddpmon ${dataDir}/elasticsearch
chown -R elasticsearch:bddpmon ${logDir}/elasticsearch
cd ${dataDir}/elasticsearch/plugins && tar -zxvf ${installDir}/install/plugins.tar.gz ; cd -
chown -R elasticsearch:bddpmon ${dataDir}/elasticsearch/plugins/
cp -pr ${confDir}/elasticsearch.yml.template /etc/elasticsearch/elasticsearch.yml

service elasticsearch start
sleep 5
curl -XPUT localhost:9200/_template/template_viewpoint -d @${installDir}/install/mapping.es.json
service elasticsearch stop

#############
# Glassfish #
#############

mkdir -p ${logDir}/glassfish
cd ${installDir}/bin/ && unzip ../thirdparties/glassfish-3.1.2.2.zip ; cd -
chown -R bddpmon:bddpmon ${installDir}/bin/glassfish3
# cp -p ${installDir}/install/glassfish /etc/init.d/glassfish
cp -pr ${confDir}/gf.domain.xml ${installDir}/bin/glassfish3/glassfish/domains/domain1/config/domain.xml
cp -pr ${confDir}/gf.viewpoint.properties ${installDir}/bin/glassfish3/glassfish/domains/domain1/config/viewpoint.properties
cp -pr ${confDir}/gf.log4j.properties ${installDir}/bin/glassfish3/glassfish/domains/domain1/config/log4j.properties

service glassfish start
${installDir}/bin/glassfish3/glassfish/bin/asadmin --passwordfile ${installDir}/install/glassfishChangePassword --user admin change-admin-password
${installDir}/bin/glassfish3/glassfish/bin/asadmin --passwordfile ${installDir}/install/glassfishPassword --user admin enable-secure-admin
cp -pr ${installDir}/install/mysql-connector-java-5.1.34-bin.jar ${installDir}/bin/glassfish3/glassfish/lib/endorsed/
service glassfish stop

#########
# Mysql #
#########

rm -fr ${dataDir}/mysql
rm -fr ${logDir}/mysql

mkdir -p ${dataDir}/mysql
mkdir -p ${logDir}/mysql
chown -R mysql:bddpmon ${dataDir}/mysql
chown -R mysql:bddpmon ${logDir}/mysql
chmod 775 ${dataDir}/mysql
chmod 775 ${logDir}/mysql
ln -nsf /data/bddpmon/viewpoint/mysql /var/lib/mysql
cp -pr ${confDir}/my.cnf.template /etc/my.cnf

mysql_install_db --user=mysql
sleep 2
/usr/sbin/mysqld -u mysql --skip-grant-tables &
sleep 2
mysql -u root < ${installDir}/install/mysql.pass.sql
pkill mysqld

sleep 2
service mysql start
sleep 2
mysql -h 127.0.0.1 -u root -p < ${installDir}/install/mysql.init.sql
service mysql stop


############
# RabbitMQ #
############
service rabbitmq-server start
rabbitmq-plugins enable rabbitmq_management

#############
# Syslog-ng #
#############
mkdir -p ${dataDir}/syslog-ng
chown -R mysql:bddpmon ${dataDir}/syslog-ng
cp -pr ${confDir}/syslog-ng.template /etc/syslog-ng/syslog-ng.conf

############
# Logstash #
############
yum -y install ${rpmDir}logstash-1.4.2-1_2c0f5a1.noarch.rpm

cp -pr ${confDir}/logstash.conf.template /etc/logstash/conf.d/10-syslog.conf
cp -pr ${confDir}/logstash.sysconfig.template /etc/sysconfig/logstash
mkdir -p ${logDir}/logstash
chown -R logstash:bddpmon ${logDir}/logstash
chmod 777 ${logDir}/logstash/



#############
# logRotate #
#############
cp -pr ${confDir}/logrotate.viewpoint.template /etc/logrotate.d/viewpoint

# Start everything
service syslog-ng start
service elasticsearch start
service mysql start
service glassfish start
service nginx start
service logstash start

# deploy App
${installDir}/bin/glassfish3/glassfish/bin/asadmin --passwordfile ${installDir}/install/glassfishPassword --user admin deploy ${installDir}/install/viewpoint-ear-1.0.0-SNAPSHOT.ear

# Post install
mysql -h 127.0.0.1 -u root -p < ${installDir}/install/mysql.post.sql

exit 0
