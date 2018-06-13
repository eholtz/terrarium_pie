#!/bin/bash

if [ -z "$(grep 10.0.0.2 /proc/mounts)" ]; then
  sudo mount -a
  exit 0
fi

for i in $(find /dev/shm/sensors/ -type f | sort); do
  while IFS=$' ' read -r -a data; do
    [ -z "${data[0]}" ] && continue
    rrdfile="/mnt/nfs/rrd/sensors/${data[0]}"
    if [ ! -f $rrdfile ]; then
      timeout 10 mkdir -p $(dirname $rrdfile)
      timeout 20 rrdcreate $rrdfile --start now-1d --step 10 DS:temperature:GAUGE:30:10:50 DS:humidity:GAUGE:30:0:100 RRA:AVERAGE:0.5:1:1d RRA:AVERAGE:0.1:5m:60d RRA:AVERAGE:0.1:1h:2y
    fi
    timeout 10 rrdtool update $rrdfile $(basename $i):${data[1]}:${data[2]}
    #echo "sensor ${data[0]}"
    #echo "temp   ${data[1]}"
    #echo "humi   ${data[2]}"
  done <$i
  sudo rm $i
done

exit 0
