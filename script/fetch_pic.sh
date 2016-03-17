#!/bin/bash

cd=$(date +%s)

TZ="Europe/Berlin"
export TZ

if [ $cd -gt $(($(/root/bin/sunrise_sunset | awk '{print $1}') - 1800)) ]; then
  if [ $cd -lt $(($(/root/bin/sunrise_sunset | awk '{print $2}') + 1800)) ]; then
    /usr/bin/fswebcam -q --set "contrast"="12%" --set "gain"="100%" --set "backlight compensation"="100%" -r 640x480 /var/www/html/rrd/current.jpg
    exit 0
  fi
fi
cp /root/dummy.jpg /var/www/html/rrd/current.jpg

