#!/bin/bash

ctz="$TZ"
TZ="Europe/Berlin"
export TZ

echo "Start Morgendaemmerung $epoch_morgendaemmerung_start / $(date -d @$epoch_morgendaemmerung_start +"%T %Z")" > $file_status
echo "Sonnenaufgang          $epoch_sonnenaufgang / $(date -d @$epoch_sonnenaufgang +"%T %Z")"                   >> $file_status
echo "Start Tageslicht       $epoch_tageslicht_start / $(date -d @$epoch_tageslicht_start +"%T %Z")"             >> $file_status
echo "Stop Tageslicht        $epoch_tageslicht_stop / $(date -d @$epoch_tageslicht_stop +"%T %Z")"               >> $file_status
echo "Sonnenuntergang        $epoch_sonnenuntergang / $(date -d @$epoch_sonnenuntergang +"%T %Z")"               >> $file_status
echo "Stop Abenddaemmerung   $epoch_abenddaemmerung_stop / $(date -d @$epoch_abenddaemmerung_stop +"%T %Z")"     >> $file_status

if [ $epoch_rain_start -gt 0 ] ; then
  echo "---" >> $file_status
  echo "Start Regen Heute $epoch_rain_start / $(date -d @$epoch_rain_start +"%T %Z")" >> $file_status
  echo "Stop Regen Heute  $epoch_rain_stop / $(date -d @$epoch_rain_stop +"%T %Z")"   >> $file_status
fi

echo "---" >> $file_status
rainfilelist=$(find $dir_volatile -iname "rain_[0-9]*" | sort)
for rf in $rainfilelist ; do
  rfc=$(cat $rf)
  if [ $rfc -gt 0 ]; then
    ard=$(echo $rf | grep -o "[0-9][0-9]$")
    raindays="$raindays $ard"
  fi
done
echo "Es wird an diesen Tagen Regnen: $raindays" >> $file_status
TZ="$ctz"
export TZ

