#!/usr/bin/env bash
set -e

# Check if service has been disabled through the DISABLED_SERVICES environment variable.

if [[ ",$(echo -e "${DISABLED_SERVICES}" | tr -d '[:space:]')," = *",$BALENA_SERVICE_NAME,"* ]]; then
        echo "$BALENA_SERVICE_NAME is manually disabled."
        sleep infinity
fi

# Verify that all the required variables are set before starting up the application.

echo "Verifying settings..."
echo " "
sleep 2

missing_variables=false

# Begin defining all the required configuration variables.

[ -z "$ADSB_EXCHANGE_SITENAME" ] && echo "ADS-B Exchange username is missing, will abort startup." && missing_variables=true || echo "ADS-B Exchange username is set: $ADSB_EXCHANGE_SITENAME"
[ -z "$ADSB_EXCHANGE_UUID" ] && echo "ADS-B Exchange UUID is missing, will abort startup." && missing_variables=true || echo "ADS-B Exchange UUID is set: $ADSB_EXCHANGE_UUID"
[ -z "$LAT" ] && echo "Receiver latitude is missing, will abort startup." && missing_variables=true || echo "Receiver latitude is set: $LAT"
[ -z "$LON" ] && echo "Receiver longitude is missing, will abort startup." && missing_variables=true || echo "Receiver longitude is set: $LON"
[ -z "$ALT" ] && echo "Receiver altitude is missing, will abort startup." && missing_variables=true || echo "Receiver altitude is set: $ALT"
[ -z "$RECEIVER_HOST" ] && echo "Receiver host is missing, will abort startup." && missing_variables=true || echo "Receiver host is set: $RECEIVER_HOST"
[ -z "$RECEIVER_PORT" ] && echo "Receiver port is missing, will abort startup." && missing_variables=true || echo "Receiver port is set: $RECEIVER_PORT"

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

# Write settings to config file and set permissions.
envsubst < /boot/adsbx-uuid.tpl > /boot/adsbx-uuid
chmod a+rw /boot/adsbx-uuid

echo "Feeder page: https://www.adsbexchange.com/api/feeders/?feed=$(cat /boot/adsbx-uuid)"
echo " "

# Start adsbexchange-feed and put it in the background.
/usr/bin/feed-adsbx --net --net-only --debug=n --quiet --write-json /run/adsbexchange-feed --net-beast-reduce-interval 0.5 --net-connector feed.adsbexchange.com,30004,beast_reduce_out,feed.adsbexchange.com,64004 --net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30154 --net-bo-port 0 --net-ri-port 0 --net-connector "$RECEIVER_HOST","$RECEIVER_PORT",beast_in --lat "$LAT" --lon "$LON" 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' |  awk -W interactive '{print "[feed-adsbx]     " $0}' &
/usr/local/share/adsbexchange/venv/bin/mlat-client --input-type dump1090 --no-udp --input-connect "$RECEIVER_HOST":"$RECEIVER_PORT" --server feed.adsbexchange.com:31090 --user "$ADSB_EXCHANGE_SITENAME" --lat "$LAT" --lon "$LON" --alt "$ALT" --results beast,connect,"$RECEIVER_HOST":30104 --results basestation,listen,31003 --results beast,listen,30157 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' | awk -W interactive '{print "[mlat-client]    "  $0}' &
/usr/local/share/adsbexchange-stats/json-status 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' | awk -W interactive '{print "[json-status]    " $0}' | grep -v 'jq: error' &


# If UAT is enabled through config, enable feeding of UAT data to ADSB Exchange.
if [[ "$UAT_ENABLED" = "true" ]]; then
	/usr/bin/feed-adsbx --net-only --net --net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ri-port 37981 --net-bo-port 37985 --net-connector feed.adsbexchange.com,30004,beast_reduce_out,feed.adsbexchange.com,64004 --write-json /run/adsbexchange-978 --quiet 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' | awk -W interactive '{print "[feed-adsbx-uat] " $0}' &
	/usr/local/share/adsbexchange-978/convert.sh 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' | awk -W interactive '{print "[uat2esnt]       " $0}' &
fi

# Wait for any services to exit.
wait -n
