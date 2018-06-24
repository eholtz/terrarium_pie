#!/bin/bash

rainpath="/dev/shm/rain/"
rainfile="$(($(date +%j) - 1))"
rainduration="$(sed '1q;d' $rainpath/$rainfile)"
rainstart="$(sed '2q;d' $rainpath/$rainfile)"
rainday="$(sed '3q;d' $rainpath/$rainfile)"

if [[ $rainstart -ne 0 ]]; then
  echo "Heute wird es Regnen"
else
  while [[ $rainduration -eq 0 ]]; do
    rainfile=$(($rainfile + 1))
    rainduration="$(sed '1q;d' $rainpath/$rainfile)"
    rainstart="$(sed '2q;d' $rainpath/$rainfile)"
    rainday="$(sed '3q;d' $rainpath/$rainfile)"
    if [[ $rainfile -gt 366 ]]; then
      rainduration=1
    fi
  done
fi
rs_hour=$(($rainstart / 3600))
rs_min=$((($rainstart - $rs_hour * 3600) / 60))
rs_sec=$(($rainstart - $rs_hour * 3600 - $rs_min * 60))
ctz=$TZ
TZ="Europe/Berlin"
export TZ
datestr=$(date --date="$rainday $rs_hour:$rs_min:$rs_sec" +"%F %T")
echo "Datum: $datestr"
echo "Dauer: $rainduration Sekunden"
TZ=$ctz
export TZ
