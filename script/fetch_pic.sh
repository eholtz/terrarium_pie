#!/bin/bash

cd /var/www/html/rrd/

cd=$(date +%s)

TZ="Europe/Berlin"
export TZ

RBF="/var/www/html/rrd/reboot2"

curl -m 55 -o /var/www/html/rrd/raw.jpg http://10.0.0.179:8080/photoaf.jpg
if [ $? -eq 0 ]; then
  rm $RBF
#  convert /var/www/html/rrd/raw.jpg -resize 50%x50% -fill white -gravity south -annotate +0+0 "Geckocam $(date +"%F %R %Z")" /var/www/html/rrd/rawt.jpg
else
  date > $RBF
#  cp /root/dummy.jpg /var/www/html/rrd/rawt.jpg
fi


