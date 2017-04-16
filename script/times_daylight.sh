#!/bin/bash

# be sure to be in utc mode
TZ="UTC"
export TZ

file_today="$dir_volatile/times_$(date +%Y%m%d)"
file_times="$dir_volatile/times"
file_epoch="$dir_volatile/times_epoch"

if [ ! -f $file_today ] ; then
  echo "File $file_today not found => assuming new day or reboot"
  echo "Cleaning up ..."
  rm -f $dir_volatile/times* &> /dev/null
  cd $dir_volatile
  echo "Calculating times ..."
  $dir_bin/timecontrol
  echo "Converting times to epoch ..."
  read msh tlh nlh ash tah toh < $file_times
  ms=$(date -d $msh +%s)
  tl=$(date -d $tlh +%s)
  nl=$(date -d $nlh +%s)
  as=$(date -d $ash +%s)
  ta=$(date -d $tah +%s)
  to=$(date -d $toh +%s)
  echo "$ms $tl $nl $as $ta $to" > $file_epoch
  echo "" > $file_today
fi

# now we need the times when sun has risen und when the sun will set
read epoch_morgendaemmerung_start epoch_tageslicht_start epoch_tageslicht_stop epoch_abenddaemmerung_stop epoch_sonnenaufgang epoch_sonnenuntergang < $file_epoch

echo "Start Morgendaemmerung $epoch_morgendaemmerung_start / $(date -d @$epoch_morgendaemmerung_start +"%T %Z")"
echo "Start Tageslicht       $epoch_tageslicht_start / $(date -d @$epoch_tageslicht_start +"%T %Z")"
echo "Stop Tageslicht        $epoch_tageslicht_stop / $(date -d @$epoch_tageslicht_stop +"%T %Z")"
echo "Stop Abenddaemmerung   $epoch_abenddaemmerung_stop / $(date -d @$epoch_abenddaemmerung_stop +"%T %Z")"
echo "Sonnenaufgang          $epoch_sonnenaufgang / $(date -d @$epoch_sonnenaufgang +"%T %Z")"
echo "Sonnenuntergang        $epoch_sonnenuntergang / $(date -d @$epoch_sonnenuntergang +"%T %Z")"

