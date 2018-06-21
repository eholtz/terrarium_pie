#!/bin/bash

if [ -z "$(grep 10.0.0.2 /proc/mounts)" ]; then
  sudo mount -a
  exit 0
fi

today=$(date +%F)
destination="/mnt/nfs/terracam/$today/"
tmpdir="/dev/shm/terracam/"

mkdir -p $tmpdir
mkdir -p $destination

timeout 40 curl -s -m 38 -o $tmpdir/camtmp.jpg http://10.0.0.70:8080/photoaf.jpg
if [ $? -eq 0 ]; then

  ctz=$TZ
  TZ="Europe/Berlin"
  export TZ
  convert $tmpdir/camtmp.jpg -resize 1920x1080 $tmpdir/camtmp.bmp
  convert $tmpdir/camtmp.bmp -fill white -font DejaVu-Sans-Bold -pointsize 24 -gravity south -annotate +0+0 "Geckocam $(date +"%F %R %Z")" -quality 80 $tmpdir/camtmptxt.jpg
  TZ=$ctz
  export TZ

  cp $tmpdir/camtmptxt.jpg "${destination}/$(date +%R).jpg"

fi
