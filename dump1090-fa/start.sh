#!/usr/bin/env bash
set -e

# Check if service has been disabled through the DISABLED_SERVICES environment variable.

if [[ ",$(echo -e "${DISABLED_SERVICES}" | tr -d '[:space:]')," = *",$BALENA_SERVICE_NAME,"* ]]; then
        echo "$BALENA_SERVICE_NAME is manually disabled."
        sleep infinity
fi
# Verify that all the required varibles are set before starting up the application.

echo "Verifying settings..."
echo " "
sleep 2

missing_variables=false

# Begin defining all the required configuration variables.

[ -z "$LAT" ] && \echo "Receiver latitude is missing, will abort startup." && missing_variables=true || echo "Receiver latitude is set: $LAT"
[ -z "$LON" ] && echo "Receiver longitude is missing, will abort startup." && missing_variables=true || echo "Receiver longitude is set: $LON"

# End defining all the required configuration variables.

echo " "

if [ "$missing_variables" = true ]
then
        echo "Settings missing, aborting..."
        echo " "
        sleep infinity
fi

echo "Settings verified, proceeding with startup."
echo " "

# Variables are verified – continue with startup procedure.

# Start dump1090-fa and put it in the background.
/usr/bin/dump1090-fa --device-type rtlsdr --device "$DUMP1090_DEVICE" --lat "$LAT" --lon "$LON" --fix --gain "$DUMP1090_GAIN" --ppm "$DUMP1090_PPM" --max-range "$DUMP1090_MAX_RANGE" --net --net-heartbeat 60 --net-ro-size 1000 --net-ro-interval 0.05 --net-http-port 0 --net-ri-port 0 --net-ro-port 30002,30102 --net-sbs-port 30003 --net-bi-port 30004,30104 --net-bo-port 30005,30105 --raw --json-location-accuracy 2 --write-json /run/dump1090-fa --quiet &
  
# Start lighthttpd and put it in the background.
/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf &
 
# Wait for any services to exit.
wait -n
