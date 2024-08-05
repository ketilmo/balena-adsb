#!/usr/bin/env bash
set -e

# Check if service has been disabled through the DISABLED_SERVICES environment variable.

if [[ ",$(echo -e "${DISABLED_SERVICES}" | tr -d '[:space:]')," = *",$BALENA_SERVICE_NAME,"* ]]; then
        echo "$BALENA_SERVICE_NAME is manually disabled."
        sleep infinity
fi

# Check if service has been enabled through the UAT_ENABLED environment variable. 

if ! [[ "$UAT_ENABLED" = "true" ]]; then
        echo "$BALENA_SERVICE_NAME is not enabled."
        sleep infinity
fi

# Verify that all the required variables are set before starting up the application.

echo "Verifying settings..."
echo " "
sleep 2

missing_variables=false

# Begin defining all the required configuration variables.

[ -z "$LAT" ] && echo "Receiver latitude is missing, will abort startup." && missing_variables=true || echo "Receiver latitude is set: $LAT"
[ -z "$LON" ] && echo "Receiver longitude is missing, will abort startup." && missing_variables=true || echo "Receiver longitude is set: $LON"
[ -z "$DUMP978_DEVICE" ] && echo "RTLSDR device not specified. Using default values." && DUMP978_DRIVER="rtlsdr" || echo "RTLSDR device specified: $DUMP978_DEVICE" && DUMP978_DRIVER="rtlsdr,serial=$DUMP978_DEVICE"

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
  
# Start dump978-fa and put it in the background.
/usr/bin/dump978-fa --sdr driver="$DUMP978_DRIVER" --raw-port 0.0.0.0:30978 --json-port 0.0.0.0:30979 --format CS8 --sdr-auto-gain &

# Start skyaware978 and put it in the background.
/usr/bin/skyaware978 --connect localhost:30978 --reconnect-interval 30 --lat "$LAT" --lon "$LON" --json-dir /run/skyaware978 &

# Start lighthttpd and put it in the background.
/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf &

# Check if device reboot on service exit has been enabled through the REBOOT_DEVICE_ON_SERVICE_EXIT environment variable.
if [[ "$REBOOT_DEVICE_ON_SERVICE_EXIT" = "true" ]]; then
        echo "Device reboot on service exit it enabled."
fi

# Wait for any services to exit.
wait -n

if [[ "$REBOOT_DEVICE_ON_SERVICE_EXIT" == "true" ]]; then
        echo "Service exited, rebooting the device..."
        dbus-send --system --print-reply --dest=org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager.Reboot
fi
