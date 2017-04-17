#!/bin/bash

ctz="$TZ"
TZ="Europe/Berlin"
export TZ

echo "Start Morgendaemmerung $epoch_morgendaemmerung_start / $(date -d @$epoch_morgendaemmerung_start +"%T %Z")" > $file_status
echo "Start Tageslicht       $epoch_tageslicht_start / $(date -d @$epoch_tageslicht_start +"%T %Z")"             >> $file_status
echo "Stop Tageslicht        $epoch_tageslicht_stop / $(date -d @$epoch_tageslicht_stop +"%T %Z")"               >> $file_status
echo "Stop Abenddaemmerung   $epoch_abenddaemmerung_stop / $(date -d @$epoch_abenddaemmerung_stop +"%T %Z")"     >> $file_status
echo "Sonnenaufgang          $epoch_sonnenaufgang / $(date -d @$epoch_sonnenaufgang +"%T %Z")"                   >> $file_status
echo "Sonnenuntergang        $epoch_sonnenuntergang / $(date -d @$epoch_sonnenuntergang +"%T %Z")"               >> $file_status

if [ $epoch_rain_start -gt 0 ] ; then
  echo "Start Regen $epoch_rain_start / $(date -d @$epoch_rain_start +"%T %Z")" >> $file_status
  echo "Stop Regen  $epoch_rain_stop / $(date -d @$epoch_rain_stop +"%T %Z")"   >> $file_status
fi

TZ="$ctz"
export TZ

