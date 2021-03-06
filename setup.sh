#!/bin/sh

set -e

fqdn_to_dn() {
	printf 'dc=%s' "$1" | sed -r 's/\./,dc=/g'
}

random_string() {
	hexdump -n 16 -v -e '/1 "%02X"' /dev/urandom
}

if [ ! -e ./docker-compose.yml ]; then
	echo "copying example compose file"
	cp docker-compose.yml-example docker-compose.yml
fi

if [ ! -e ./.env ]; then
	PRINT_SETUP_SUCCESS=""

	echo "Creating an .env file for you"
	value_default=latest
	read -p "Which tag do you want to use for Kopano Core components? [$value_default]: " new_value
	CORE_VERSION=${new_value:-$value_default}

	value_default=latest
	read -p "Which tag do you want to use for Kopano WebApp? [$value_default]: " new_value
	WEBAPP_VERSION=${new_value:-$value_default}

	value_default="Kopano Demo"
	read -p "Name of the Organisation for LDAP [$value_default]: " new_value
	LDAP_ORGANISATION=${new_value:-$value_default}

	value_default="kopano.demo"
	read -p "FQDN to be used (for reverse proxy) [$value_default]: " new_value
	FQDN=${new_value:-$value_default}

	value_default="self_signed"
	read -p "Email address to use for Lets Encrypt. Use 'self_signed' as your email to create self signed certificates [$value_default]: " new_value
	EMAIL=${new_value:-$value_default}

	LDAP_BASE_DN=$(fqdn_to_dn $FQDN)
	value_default="$LDAP_BASE_DN"
	read -p "Name of the BASE DN for LDAP [$value_default]: " new_value
	LDAP_BASE_DN=${new_value:-$value_default}

	value_default="ldap://ldap:389"
	read -p "LDAP server to be used (defaults to the bundled OpenLDAP) [$value_default]: " new_value
	LDAP_SERVER=${new_value:-$value_default}

	if [ "$LDAP_SERVER" != "$value_default" ]; then
		# We don't need an admin password in case we don't use the bundled LDAP server
		LDAP_ADMIN_PASSWORD=""

		value_default="$LDAP_BASE_DN"
		read -p "LDAP search base [$value_default]: " new_value
		LDAP_SEARCH_BASE=${new_value:-$value_default}

		value_default="cn=readonly,$LDAP_BASE_DN"
		read -p "LDAP bind user (needs read permissions) [$value_default]: " new_value
		LDAP_BIND_DN=${new_value:-$value_default}

		value_default="kopano123"
		read -p "LDAP bind password to be used [$value_default]: " new_value
		LDAP_BIND_PW=${new_value:-$value_default}

		PRINT_SETUP_SUCCESS="$PRINT_SETUP_SUCCESS \n!! You have specified the LDAP server '${LDAP_SERVER}', don't forget to remove the bundled ldap and ldap-admin services in docker-compose.yml\n"
	else
		LDAP_ADMIN_PASSWORD=$(random_string)
		LDAP_SEARCH_BASE="$LDAP_BASE_DN"
		LDAP_BIND_DN="cn=readonly,$LDAP_BASE_DN"
		LDAP_BIND_PW=$(random_string)
	fi

	if [ -f /etc/timezone ]; then
		value_default=$(cat /etc/timezone)
	elif [ -f /etc/localtime ]; then
		value_default=$(readlink /etc/localtime|sed -n 's|^.*zoneinfo/||p')
	fi

	if [ -z "${value_default}" ]; then
		value_default="Europe/Berlin".
	fi

	read -p "Timezone to be used [$value_default]: " new_value
	TZ=${new_value:-$value_default}

	value_default="postmaster@$FQDN"
	read -p "E-Mail Address displayed for the 'postmaster' [$value_default]: " new_value
	POSTMASTER_ADDRESS=${new_value:-$value_default}

	value_default="db"
	read -p "Name/Address of Database server (defaults to the bundled one) [$value_default]: " new_value
	MYSQL_HOST=${new_value:-$value_default}

	if [ "$MYSQL_HOST" != "$value_default" ]; then
		# We don't need an admin password in case we don't use the bundled DB server
		MYSQL_ROOT_PASSWORD=""

		value_default="kopanoDbUser"
		read -p "Username to connect to the database [$value_default]: " new_value
		MYSQL_USER=${new_value:-$value_default}

		value_default="kopanoDbPw"
		read -p "Password to connect to the database [$value_default]: " new_value
		MYSQL_PASSWORD=${new_value:-$value_default}

		value_default="kopano"
		read -p "Database to use for Kopano [$value_default]: " new_value
		MYSQL_DATABASE=${new_value:-$value_default}

		PRINT_SETUP_SUCCESS="$PRINT_SETUP_SUCCESS \n!! You have specified the DB server '${MYSQL_HOST}', don't forget to remove the bundled db service in docker-compose.yml\n"
	else
		MYSQL_USER="kopano"
		MYSQL_DATABASE="kopano"
		MYSQL_ROOT_PASSWORD=$(random_string)
		MYSQL_PASSWORD=$(random_string)
    fi

    echo ${PRINT_SETUP_SUCCESS}

        cat <<-EOF >"./.env"
# please consult https://github.com/zokradonh/kopano-docker
# for possible configuration values and their impact
CORE_VERSION=$CORE_VERSION
WEBAPP_VERSION=$WEBAPP_VERSION

LDAP_ORGANISATION="$LDAP_ORGANISATION"
LDAP_DOMAIN=$FQDN
LDAP_BASE_DN=$LDAP_BASE_DN
LDAP_SERVER=$LDAP_SERVER
LDAP_ADMIN_PASSWORD=$LDAP_ADMIN_PASSWORD
LDAP_READONLY_USER_PASSWORD=$LDAP_BIND_PW
LDAP_BIND_DN=$LDAP_BIND_DN
LDAP_BIND_PW=$LDAP_BIND_PW
LDAP_SEARCH_BASE=$LDAP_SEARCH_BASE

# LDAP query filters
LDAP_QUERY_FILTER_USER=(&(kopanoAccount=1)(mail=%s))
LDAP_QUERY_FILTER_GROUP=(&(objectclass=kopano-group)(mail=%s))
LDAP_QUERY_FILTER_ALIAS=(&(kopanoAccount=1)(kopanoAliases=%s))
LDAP_QUERY_FILTER_DOMAIN=(&(|(mail=*@%s)(kopanoAliases=%s=*@%s)))
SASLAUTHD_LDAP_FILTER=(&(kopanoAccount=1)(uid=%s))

# switch the value of these two variables to use the activedirectory configuration
KCUNCOMMENT_LDAP_1=!include /usr/share/kopano/ldap.openldap.cfg
KCCOMMENT_LDAP_1=!include /usr/share/kopano/ldap.active-directory.cfg

MYSQL_HOST=$MYSQL_HOST
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_DATABASE=$MYSQL_DATABASE

KCCONF_SERVER_SERVER_NAME=Kopano

POSTMASTER_ADDRESS=$POSTMASTER_ADDRESS
TZ=$TZ

# Defines how Kopano can be accessed from the outside world
FQDN=$FQDN
EMAIL=$EMAIL
HTTP=80
HTTPS=443

# Docker Repository to push to
docker_repo=zokradonh

# modify below to build a different version, than the kopano nightly release
#KOPANO_CORE_REPOSITORY_URL=https://serial:REPLACE-ME@download.kopano.io/supported/core:/final/Debian_9.0/
#KOPANO_WEBAPP_REPOSITORY_URL=https://serial:REPLACE-ME@download.kopano.io/supported/webapp:/final/Debian_9.0/
#KOPANO_ZPUSH_REPOSITORY_URL=http://repo.z-hub.io/z-push:/final/Debian_9.0/
#RELEASE_KEY_DOWNLOAD=1
#DOWNLOAD_COMMUNITY_PACKAGES=0

EOF
else
	echo "config already exists, doing nothing"
	echo "if you want to change the configuration, please edit .env directly"
fi
