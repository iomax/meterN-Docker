#!/bin/bash

function logTitle() {
	echo -e "\e[34m######### $1 #########\033[0m"
}

function logSubTitle() {
	echo -e "\e[34m# $1 \033[0m"
}

function logNormal() {
	echo -e "\033[0;32m$1\033[0m"
}

function logError() {
	echo -e "\033[0;31m$1\033[0m"
}

logTitle "Update checking started for meterN"

rawLastVersMetern=$(curl -f -s https://metern.org/latest_version.php)
if [[ $? -ne 0 ]] ; then
	logError "Error retrieving meternN last version. Exiting."
	exit 1
fi

lastVersMetern=$(echo $rawLastVersMetern |php -r 'echo json_decode(fgets(STDIN))->LASTVERSION;' |cut -d ' ' -f2)

instVersMetern=$(grep VERSION /var/www/metern/scripts/version.php |cut -d \' -f2 |cut -d ' ' -f2)

logSubTitle "[meterN] Installed version: $instVersMetern"
logSubTitle "[meterN] Last version: $lastVersMetern"
echo " "

if [ "$lastVersMetern" == "$instVersMetern" ]; then
	logNormal "Last version already installed"
	logTitle "Update checking done"
	exit 0
fi

logSubTitle "Updating system components (wget and ca-certificates)..."
apk update && \
apk --no-cache add \
	ca-certificates \
	wget && \
update-ca-certificates
if [[ $? -ne 0 ]] ; then
	logError "Error during system components update."
else
	logNormal "System components updated successfully"
fi


if [ "$lastVersMetern" != "$instVersMetern" ]; then
	logSubTitle "[meterN] Updating..."
	
	linkMetern=$(echo $rawLastVersMetern |php -r 'echo json_decode(fgets(STDIN))->LINK;') && \
	mkdir -p /tmp/meternUpdate && \
	cd /tmp/meternUpdate && \
	wget -q $linkMetern && \
	tar -xzf metern*.tar.gz && \
	rm -rf metern*.tar.gz
	if [[ $? -ne 0 ]] ; then
		logError "Error during meterN download/unpack. Exiting."
		logTitle "Update checking done"
		exit 1
	fi

	# Do not overwrite config and data directories
	if [ "$instVersMetern" != "0.0" ]; then
		if [ -d /var/www/metern/config ]; then
			rm -rf metern/config/
		fi
		if [ -d /var/www/metern/data ]; then
			rm -rf metern/data/
		fi
	else
		# On first copy, keep the config_daemon.php supplied with this image
		rm metern/config/config_daemon.php
	fi

	cp -Rf metern/* /var/www/metern/ && \
	cd / && \
	rm -rf /tmp/meternUpdate && \
	chown -R nginx:www-data /var/www/metern

	if [[ $? -ne 0 ]] ; then
		logError "Error during meterN update. Exiting."
		logTitle "Update checking done"
		exit 1
	else
		logNormal "meterN updated successfully"
	fi
fi

logTitle "Update checking done"
