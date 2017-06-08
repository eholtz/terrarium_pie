#!/bin/bash

# be sure to be in utc mode
TZ="UTC"
export TZ

file_rainthismonth="$dir_volatile/rain_$(date +%Y%m)"
file_raintoday="$dir_volatile/rain_$(date +%Y%m%d)"

if [ ! -f $file_raintoday ] ; then
  echo "File $file_raintoday missing => assuming new month or reboot"
  echo "Cleaning up ..."
  rm -f $dir_volatile/rain* &> /dev/null
  echo "Calculating if it will rain ..."
  thismonth=$(date +%m)
  daycount=0
  epochmidnight=$(date -d "today 0:00" +%s)
  secondstodaystart=$(($epoch_tageslicht_start-$epochmidnight))
  while [ $(date -d "+ $daycount day" +%m) -eq $thismonth ]; do
    file_rainduration="$dir_volatile/rain_duration_$(date -d "+ $daycount day" +%Y%m%d)"
    file_raintoday="$dir_volatile/rain_$(date -d "+ $daycount day" +%Y%m%d)"
    rn=$RANDOM
    res=$(($rn % 4))
    echo "Random number is $rn - calculation is $res"
    # it will rain about once every four days
    if [ $res -eq 0 ] ; then
      echo $((($RANDOM % ($epoch_tageslicht_stop-$epoch_tageslicht_start))+$(date -d "+ $daycount day 0:00" +%s)+$secondstodaystart)) > $file_raintoday
      echo $((($RANDOM % 15)*60+300)) > $file_rainduration
    else
      echo "0" > $file_raintoday
      echo "0" > $file_rainduration
    fi
    daycount=$(($daycount+1))

  done
fi

file_rainduration="$dir_volatile/rain_duration_$(date +%Y%m%d)"
file_raintoday="$dir_volatile/rain_$(date +%Y%m%d)"


read epoch_rain_start < $file_raintoday
read epoch_rain_duration < $file_rainduration
epoch_rain_stop=$(($epoch_rain_start+$epoch_rain_duration))

echo "Start Regen $epoch_rain_start / $(date -d @$epoch_rain_start +"%T %Z")"
echo "Stop Regen  $epoch_rain_stop / $(date -d @$epoch_rain_stop +"%T %Z")"
echo "Regendauer  $epoch_rain_duration"

