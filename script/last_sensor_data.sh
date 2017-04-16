#!/bin/bash

declare -A temperature

for i in "${!sensors[@]}" ; do
  sensorfile="${rrd_sensor}_${sensors[$i]}"
  temperature[$i]=$(rrdtool lastupdate $sensorfile | tail -n 1 | awk '{print $2}')
  echo "Temperature from sensor ${sensors[$i]} (${sensoridname[$i]}) is ${temperature[$i]}"
done

