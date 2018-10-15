#!/bin/bash

set -eu # unset variables are errors & non-zero return values exit the whole script

socket_path=/var/run/kopano-grapi
mkdir -p /tmp/$SERVICE_TO_START /var/run/kopano $socket_path

echo "Set ownership" | ts
chown -R kopano:kopano /run /tmp
chown kopano:kopano /kopano/data/ /kopano/data/attachments
chown -R kapi:kopano $socket_path

# allow helper commands given by "docker-compose run"
if [ $# -gt 0 ]
then
    exec "$@"
    exit
fi

source /etc/kopano/grapi.cfg
exec /usr/sbin/kopano-grapi serve
