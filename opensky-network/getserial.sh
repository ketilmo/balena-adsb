#!/usr/bin/env bash
set -e

# Verify that all the required variables are set before starting up the application.

echo "Verifying required settings..."
echo " "
sleep 2


missing_variables=false

# Begin defining all the required configuration variables.

[ -z "$OPENSKY_USERNAME" ] && echo "OpenSky Network Username is missing, aborting." && missing_variables=true || echo "OpenSky Network Username is set: $OPENSKY_USERNAME"
[ -z "$LAT" ] && echo "Receiver latitude is missing, aborting." && missing_variables=true || echo "Receiver latitude is set: $LAT"
[ -z "$LON" ] && echo "Receiver longitude is missing, aborting." && missing_variables=true || echo "Receiver longitude is set: $LON"
[ -z "$ALT" ] && echo "Receiver altitude is missing, aborting." && missing_variables=true || echo "Receiver altitude is set: $ALT"
[ -z "$RECEIVER_HOST" ] && echo "Receiver host is missing, aborting." && missing_variables=true || echo "Receiver host is set: $RECEIVER_HOST"
[ -z "$RECEIVER_PORT" ] && echo "Receiver port is missing, aborting." && missing_variables=true || echo "Receiver port is set: $RECEIVER_PORT"

# End defining all the required configuration variables.

echo " "

if [ "$missing_variables" = true ]
then
        echo "Required settings missing, aborting."
        echo " "
        exit 0

fi

# Copy environment variables to config file

envsubst < /var/lib/openskyd/conf.tpl/10-debconf.conf.tpl> /var/lib/openskyd/conf.d/10-debconf.conf

missing_serial=false

# Check if the serial number is already retrieved

[ -z "$OPENSKY_SERIAL" ] && echo "OpenSky Network Serial is not configured." && missing_serial=true || echo "OpenSky Network Serial is already configured: $OPENSKY_SERIAL"

# Serial not found. Retrieve it from OpenSky Network.

if [ "$missing_serial" = true ]
then
	echo " "
	echo "Requesting new OpenSky Network Serial for username $OPENSKY_USERNAME"
	echo " "

	sleep 2

	command="/usr/bin/openskyd-dump1090"
	log="serial.log"
	match="Sending Username"

	$command | tee "$log" 2>&1 &
	pid=$!

	missing_serial=true

	while missing_serial=true
	do
	    if fgrep --quiet  "$match" "$log"
	    then
	    	echo " "
	        cat /var/lib/openskyd/conf.d/05-serial.conf |grep =
	        echo " "
	        echo "Please add the serial number above to a balena environment variable named OPENSKY_SERIAL"
	        rm "$log"
	        kill $pid
	        exit 0
	    fi
	done

fi