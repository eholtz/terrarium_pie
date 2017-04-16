#!/bin/bash

for i in "${sensors[@]}" ; do
  sensorfile="${rrd_sensor}_$i"
  if [ ! -f $sensorfile ] ; then
    # every minute
    # keep 1 minute step for one day
    # keep 5 minutes step for 63 days
    # keep 1 hour step for a bit more than two years
    rrdcreate $sensorfile --start now-1d --step 60 DS:temperature:GAUGE:120:15:45 DS:humidity:GAUGE:120:0:100 RRA:AVERAGE:0.5:1:1440 RRA:AVERAGE:0.1:5:18000 RRA:AVERAGE:0.1:60:18000
  fi

  # now that we are sure to have the sensor file read the values
  timeout 10 "$dir_bin/read_sensor_$i" | tr '\n' ' ' > $dir_tmp/data_sensor_$i
  read temp humi < $dir_tmp/data_sensor_$i
  timeout 10 rrdtool update $sensorfile N:$temp:$humi

done
