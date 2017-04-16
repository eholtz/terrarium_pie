#!/bin/bash

declare -A temperature

for i in "${!sensors[@]}" ; do
  sensorfile="${rrd_sensor}_${sensors[$i]}"
  temp=$(rrdtool lastupdate $sensorfile | tail -n 1 | awk '{print $2}')
  temperature[$i]=$(echo $temp | cut -d '.' -f 1)
  echo "Temperature from sensor ${sensors[$i]} (${sensoridname[$i]}) is ${temperature[$i]} ($temp)"
done

