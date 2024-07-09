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

[ -z "$WINGBITS_DEVICE_ID" ] && echo "Wingbits Device ID is missing, will abort startup." && missing_variables=true || echo "Wingbits Device ID is set: $WINGBITS_DEVICE_ID"
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

# Check if Wingbits is latest version

local_version=$(cat /etc/wingbits/version)
echo "Current local version: $local_version"

SCRIPT_URL="https://gitlab.com/wingbits/config/-/raw/master/download.sh"
script=$(curl $SCRIPT_URL)
version=$(echo "$script" | grep -oP '(?<=WINGBITS_CONFIG_VERSION=")[^"]*')
echo "Latest available wingbits version: $version"

if [ "$version" != "$local_version" ] || [ -z "$version" ]; then
    echo "WARNING: You are not running the latest Wingbits version. Please update at your earliest convenience."
else
    echo "Wingbits is up to date"
fi

echo " "

# Variables are verified – continue with startup procedure.

# Start vector and readsb and put in the background.
/usr/bin/vector --watch-config &
/usr/bin/feed-wingbits --net --net-only --debug=n --quiet --net-connector localhost,30006,json_out --write-json /run/wingbits-feed --net-beast-reduce-interval 0.5 --net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30154 --net-bo-port 0 --net-ri-port 0 --net-connector "$RECEIVER_HOST","$RECEIVER_PORT",beast_in 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' |  awk -W interactive '{print "[readsb-wingbits]     " $0}' &

# Wait for any services to exit.
wait -n
