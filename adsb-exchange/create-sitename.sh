#!/usr/bin/env bash
echo " "
echo "Please enter a unique name for the feeder to be shown on the MLAT matrix (http://adsbx.org/sync)"
echo "This name MUST be unique, for this reason a random number is automatically added at the end."
echo "Text and Numbers only - everything else will be removed."
echo "Example: \"william34-london\", \"william34-jersey\", etc."
echo " "

read INPUT_USERNAME

# Make sure sitename is compliant
NOSPACENAME="$(echo -n -e "$INPUT_USERNAME" | tr -c '[a-zA-Z0-9]_\-' '_')_$((RANDOM % 90 + 10))"
echo " "
echo "Please add the site name below to a balena environment variable named ADSB_EXCHANGE_SITENAME"
echo "(If you are not happy about the results, you can run this script again to create a new one.)"
echo " "

echo "Site name: $NOSPACENAME"