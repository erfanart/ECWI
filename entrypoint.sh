#!/bin/bash
# Ensure directories exist
mkdir -p /var/log/apache2
mkdir -p /etc/apache2

# Copy default configuration files if they don't exist
if [ ! -d "/var/log/apache2" ]; then
  cp -r /var/log/apache2-default/*  /var/log/apache2/
fi

if [ ! -d "/etc/apache2" ]; then
  cp -r /etc/apache2-default/* /etc/apache2/
fi

apachectl start &
exec "$@"
# Start Jira
