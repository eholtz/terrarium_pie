#!/bin/bash

# be sure to be in utc mode
TZ="UTC"
export TZ

file_today="$dir_volatile/times_$(date +%Y%m%d)"
file_times="$dir_volatile/times"
file_epoch="$dir_volatile/times_epoch"

if [ ! -f $file_today ] ; then
  rm -f $dir_volatile/times* &> /dev/null
  cd $dir_volatile
  $bin_dir/timecontrol
  read msh tlh nlh ash tah toh < $file_time
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


