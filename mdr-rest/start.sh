#!/usr/bin/env bash

set -e

sed -i "s%{tomcat-username}%${TOMCAT_USERNAME}%"        /usr/local/tomcat/conf/tomcat-users.xml
sed -i "s%{tomcat-password}%${TOMCAT_PASSWORD}%"        /usr/local/tomcat/conf/tomcat-users.xml

sed -i "s%{postgres-host}%${DB_HOST}%"            /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-port}/${DB_PORT:-5432}/"      /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-db}/${DB_NAME}/"                /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-user}/${DB_USER}/"            /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-pass}/${DB_PASSWORD}/"            /etc/samply/mdr.postgres.xml

sed -i "s%{auth-host}%${AUTH_HOST}%"                    /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-public-key}%${AUTH_PUBKEY}%"        /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-client-id}%${AUTH_CLIENT_ID}%"          /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-client-secret}%${AUTH_CLIENT_SECRET}%"  /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-realm}%${AUTH_REALM}%"  /etc/samply/mdr.oauth2.xml

sed -i "s%{log-level}%${LOG_LEVEL:-info}%"      /etc/samply/log4j2.xml

export CATALINA_OPTS="${CATALINA_OPTS} -javaagent:/samply/jmx_prometheus_javaagent-0.15.0.jar=9100:/samply/jmx-exporter.yml"

# Replace start.sh with catalina.sh
exec /usr/local/tomcat/bin/catalina.sh run
