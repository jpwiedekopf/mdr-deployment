#!/usr/bin/env bash

set -e

### Move files from ROOT to a different deployment context
if [ -n "$DEPLOYMENT_CONTEXT" ]; then
  echo "Info: Changing deployment context of application from ROOT to $DEPLOYMENT_CONTEXT";
  if [ -d "$CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT" ]; then
    echo "Error: The directory $CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT already exists. Aborting startup!";
    exit 17;
  fi
  mkdir -p "$CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT";
  mv "$CATALINA_HOME/webapps/ROOT/"* "$CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT";
  rm -r "$CATALINA_HOME/webapps/ROOT/";
fi

sed -i "s%{tomcat-username}%${TOMCAT_USERNAME}%"        /usr/local/tomcat/conf/tomcat-users.xml
sed -i "s%{tomcat-password}%${TOMCAT_PASSWORD}%"        /usr/local/tomcat/conf/tomcat-users.xml

sed -i "s%{postgres-host}%${DB_HOST}%"            /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-port}/${DB_PORT}/"      /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-db}/${DB_NAME}/"                /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-user}/${DB_USER}/"            /etc/samply/mdr.postgres.xml
sed -i "s/{postgres-pass}/${DB_PASSWORD}/"            /etc/samply/mdr.postgres.xml

sed -i "s%{auth-host}%${AUTH_HOST}%"                    /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-public-key}%${AUTH_PUBKEY}%"        /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-client-id}%${AUTH_CLIENT_ID}%"          /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-client-secret}%${AUTH_CLIENT_SECRET}%"  /etc/samply/mdr.oauth2.xml
sed -i "s%{auth-realm}%${AUTH_REALM}%"  /etc/samply/mdr.oauth2.xml

sed -i "s%{log-level}%${LOG_LEVEL:-info}%"  /etc/samply/log4j2.xml

export CATALINA_OPTS="${CATALINA_OPTS} -javaagent:/samply/jmx_prometheus_javaagent-0.15.0.jar=9100:/samply/jmx-exporter.yml"

if [ -n "$TOMCAT_REVERSEPROXY_FQDN" ]; then
  echo "Info: Configuring reverse proxy for URL $TOMCAT_REVERSEPROXY_FQDN";
  mv $CATALINA_HOME/conf/server.xml $CATALINA_HOME/conf/server.xml.ori;
  ## Apply add reversproxy configuration to
  echo "Info: applying $CATALINA_HOME/conf/server.reverseproxy.patch on $CATALINA_HOME/conf/server.xml"
  patch -i $CATALINA_HOME/conf/tomcat.reverseproxy.patch -o $CATALINA_HOME/conf/server.xml $CATALINA_HOME/conf/server.xml.ori
  case "$TOMCAT_REVERSEPROXY_SSL" in
    true)
      : "${TOMCAT_REVERSEPROXY_PORT:=443}"
      TOMCAT_REVERSEPROXY_SCHEME=https
      ;;
    false)
      : "${TOMCAT_REVERSEPROXY_PORT:=80}"
      TOMCAT_REVERSEPROXY_SCHEME=http
      ;;
    *)
      echo "Error: Please set TOMCAT_REVERSEPROXY_SSL to either true or false."
      exit 1
  esac
  echo "Info: Applying configuration for ReverseProxy with settings: TOMCAT_REVERSEPROXY_FQDN=$TOMCAT_REVERSEPROXY_FQDN TOMCAT_REVERSEPROXY_PORT=$TOMCAT_REVERSEPROXY_PORT TOMCAT_REVERSEPROXY_SSL=$TOMCAT_REVERSEPROXY_SSL"
  sed -i -e "s|{tomcat_reverseproxy_fqdn}|$TOMCAT_REVERSEPROXY_FQDN|g ; \
  	s|{tomcat_reverseproxy_scheme}|$TOMCAT_REVERSEPROXY_SCHEME|g ; \
  	s|{tomcat_reverseproxy_port}|$TOMCAT_REVERSEPROXY_PORT|g ; \
  	s|{tomcat_reverseproxy_ssl}|$TOMCAT_REVERSEPROXY_SSL|g" \
  	$CATALINA_HOME/conf/server.xml;
  chown -R $COMPONENT:www-data $CATALINA_HOME/conf/server.xml;
  echo "Info: ReverseProxy configuration is finished"
fi

# Replace start.sh with catalina.sh
exec /usr/local/tomcat/bin/catalina.sh run
