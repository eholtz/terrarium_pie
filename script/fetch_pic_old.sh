#!/bin/bash

cd /var/www/html/rrd/

cd=$(date +%s)

TZ="Europe/Berlin"
export TZ

if [ $cd -gt $(($(/root/bin/sunrise_sunset | awk '{print $1}') - 1800)) ]; then
  if [ $cd -lt $(($(/root/bin/sunrise_sunset | awk '{print $2}') + 1800)) ]; then
      #/usr/bin/fswebcam -q --set "contrast"="12%" --set "gain"="100%" --set "backlight compensation"="100%" -r 640x480 /var/www/html/rrd/current.jpg
      /usr/bin/fswebcam  --no-banner -q --set "gain"="100%" --flip h,v -r 640x480 /var/www/html/rrd/raw.jpg
#      /root/script/autotone -n -WN m -GN m -M 0.5 /var/www/html/rrd/current.jpg /var/www/html/rrd/current2.jpg
#      /root/script/autotone2 /var/www/html/rrd/current.jpg /var/www/html/rrd/current2.jpg
      /root/script/autowhite /var/www/html/rrd/raw.jpg /var/www/html/rrd/current.jpg
#      convert /var/www/html/rrd/raw.jpg -background seagreen label:"$(date)" -gravity Center -append /var/www/html/rrd/rawt.jpg
      convert /var/www/html/rrd/raw.jpg -fill white -gravity south -annotate +0+0 "Geckocam $(date +"%F %R %Z")" /var/www/html/rrd/rawt.jpg 
      convert /var/www/html/rrd/current.jpg -fill white -gravity south -annotate +0+0 "Geckocam $(date +"%F %R %Z")" /var/www/html/rrd/currentt.jpg 
      #convert /var/www/html/rrd/current.jpg -fill white -undercolor '#005555ff' -gravity south -annotate +0+0 " $(date) " /var/www/html/rrd/currentt.jpg 
      #-fill seagreen -draw 'rectangle 0,465,640,480' -fill white -annotate "$(date)" -gravity Center -append /var/www/html/rrd/currentt.jpg
#      /root/script/autogamma /var/www/html/rrd/current.jpg /var/www/html/rrd/current4.jpg
#      /root/script/autolevel /var/www/html/rrd/current.jpg /var/www/html/rrd/current5.jpg
      exit 0
  fi
fi
cp /root/dummy.jpg /var/www/html/rrd/currentt.jpg

