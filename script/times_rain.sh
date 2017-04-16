#!/bin/bash

# be sure to be in utc mode
TZ="UTC"
export TZ

file_raintoday="$dir_volatile/rain_$(date +%Y%m%d)"
file_rainduration="$dir_volatile/rain_duration"

if [ ! -f $file_raintoday ] ; then
  rm -f $dir_volatile/rain* &> /dev/null
  # it will rain about once every four days
  if [ $(($RANDOM % 4)) -eq 0 ] ; then
    echo $((($RANDOM % ($epoch_tageslicht_stop-$epoch_tageslicht_start))+$epoch_tageslicht_start)) > $file_raintoday
    echo $((($RANDOM % 15)*60+300)) > $file_rainduration
  else
    echo "0" > $file_raintoday
    echo "0" > $file_rainduration
  fi
fi

read epoch_rain_start < $file_raintoday
read epoch_rain_duration < $file_rainduration
epoch_rain_stop=$(($epoch_rain_start+$epoch_rain_duration))


