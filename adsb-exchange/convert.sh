#!/bin/bash

while sleep 5
do
	socat -d -u "TCP:dump978-fa:30978,keepalive,keepidle=30,keepintvl=30,keepcnt=2" STDOUT | "/usr/local/share/adsbexchange-978/uat2esnt" -t \
        | socat -d -u STDIN "TCP:localhost:37981,keepalive,keepidle=30,keepintvl=30,keepcnt=2"
done