#!/usr/bin/env bash
echo " "
echo "Please enter a unique name to be shown on the MLAT map (https://map.adsbexchange.com/mlat-map)(the pin will be offset for privacy)"
echo "Example: \"william34-london\", \"william34-jersey\", etc."
echo " "

read INPUT_USERNAME

# Make sure sitename is compliant
NOSPACENAME="$(echo -n -e "$INPUT_USERNAME" | tr -c '[a-zA-Z0-9]_\- ' '_')"

echo " "
echo "Please add the site name below to a balena environment variable named ADSB_EXCHANGE_SITENAME"
echo "(If you are not happy about the results, you can run this script again to create a new one.)"
echo " "

echo "Site name: $NOSPACENAME"
