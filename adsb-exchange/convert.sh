#!/bin/bash

SOURCE="dump978-fa:30978"
TARGET="localhost:37981"
SO_OPTIONS="keepalive,keepidle=30,keepintvl=30,keepcnt=2"

while sleep 5
do
	socat -d -u "TCP:$SOURCE,$SO_OPTIONS" STDOUT \
        | /usr/local/share/adsbexchange-978/uat2esnt \
        | socat -d -u STDIN "TCP:$TARGET,$SO_OPTIONS"
done
