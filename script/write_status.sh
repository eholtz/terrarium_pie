#!/bin/bash

statusfile="${dir_volatile}/status"

ctz="$TZ"
TZ="Europe/Berlin"
export TZ

echo "Start Morgendaemmerung $epoch_morgendaemmerung_start / $(date -d @$epoch_morgendaemmerung_start +"%T %Z")"
echo "Start Tageslicht       $epoch_tageslicht_start / $(date -d @$epoch_tageslicht_start +"%T %Z")"
echo "Stop Tageslicht        $epoch_tageslicht_stop / $(date -d @$epoch_tageslicht_stop +"%T %Z")"
echo "Stop Abenddaemmerung   $epoch_abenddaemmerung_stop / $(date -d @$epoch_abenddaemmerung_stop +"%T %Z")"
echo "Sonnenaufgang          $epoch_sonnenaufgang / $(date -d @$epoch_sonnenaufgang +"%T %Z")"
echo "Sonnenuntergang        $epoch_sonnenuntergang / $(date -d @$epoch_sonnenuntergang +"%T %Z")"

if [ $epoch_rain_start -gt 0 ] ; then
  echo "Start Regen $epoch_rain_start / $(date -d @$epoch_rain_start +"%T %Z")"
  echo "Stop Regen  $epoch_rain_stop / $(date -d @$epoch_rain_stop +"%T %Z")"
fi

TZ="$ctz"
export TZ

