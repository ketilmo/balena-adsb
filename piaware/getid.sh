#!/usr/bin/env bash
set -e
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

# Verify that all the required variables are set before starting up the application.

echo "Verifying required settings..."
echo " "
sleep 2


missing_variables=false

# Begin defining all the required configuration variables.

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

# Configure piaware according to environment variables.
/usr/bin/piaware-config allow-auto-updates no
/usr/bin/piaware-config allow-manual-updates no
/usr/bin/piaware-config	allow-mlat yes
/usr/bin/piaware-config mlat-results yes
/usr/bin/piaware-config mlat-results-format "beast,connect,${RECEIVER_HOST}:${RECEIVER_MLAT_PORT} beast,listen,30105 ext_basestation,listen,30106"
/usr/bin/piaware-config receiver-type other
/usr/bin/piaware-config receiver-host "${RECEIVER_HOST}"
/usr/bin/piaware-config receiver-port "${RECEIVER_PORT}"

# Add FlightAware Feeder ID if present.
if [ -n "${FLIGHTAWARE_FEEDER_ID}" ]; then
  /usr/bin/piaware-config feeder-id "${FLIGHTAWARE_FEEDER_ID}"
fi

# If UAT is enabled through config, enable it in PiAware.
if [[ "$UAT_ENABLED" = "true" ]]; then
	/usr/bin/piaware-config uat-receiver-type other
    /usr/bin/piaware-config uat-receiver-host dump978-fa
    /usr/bin/piaware-config uat-receiver-port 30978
else
	/usr/bin/piaware-config uat-receiver-type none

fi

missing_serial=false

# Check if the serial number is already retrieved

[ -z "$FLIGHTAWARE_FEEDER_ID" ] && echo "FlightAware feeder id is not configured." && missing_serial=true || echo "FlightAware feeder id is already configured: $FLIGHTAWARE_FEEDER_ID"

# Serial not found. Retrieve it from OpenSky Network.

if [ "$missing_serial" = true ]
then
	echo " "
	echo "Requesting new FlightAware feeder id"
	echo " "

	sleep 2

	command="unbuffer /usr/bin/piaware -plainlog"
	log="serial.log"
	match="my feeder ID is"

	$command | tee "$log" 2>&1 &
	pid=$!

	missing_serial=true

	while missing_serial=true
	do
	    if fgrep --quiet  "$match" "$log"
	    then
	    	kill $pid
	    	echo " "
	    	echo "Your FlightAware feeder is:"
	        myfeederid=$(cat $log | grep "my feeder ID is")
	        echo ${myfeederid/my feeder ID is /}
	        echo " "
	        echo "Please add the serial number above to a balena environment variable named FLIGHTAWARE_FEEDER_ID"
	        echo " "
	        rm "$log"
	        exit 0
	    fi
	done

fi