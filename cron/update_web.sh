#!/bin/bash

rainpath="/dev/shm/rain/"
rainfile="$(($(date +%j) - 1))"
rainduration="$(sed '1q;d' $rainpath/$rainfile)"
rainstart="$(sed '2q;d' $rainpath/$rainfile)"
rainday="$(sed '3q;d' $rainpath/$rainfile)"

# dave current timezone and set it to europe/berlin
ctz=$(date +%Z)
TZ="Europe/Berlin"
export TZ

if [[ $rainstart -ne 0 ]]; then
  echo "Heute ist Regentag"
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
  datestr=$(date --date="$rainday 01:23:45 $ctz" +%F)
  echo "Nächster Regen: $datestr"
fi
rs_hour=$(($rainstart / 3600))
rs_min=$((($rainstart - $rs_hour * 3600) / 60))
rs_sec=$(($rainstart - $rs_hour * 3600 - $rs_min * 60))
datestr=$(date --date="$rainday $rs_hour:$rs_min:$rs_sec $ctz" +%T)
echo "Uhrzeit: $datestr"
echo "Dauer: $rainduration Sekunden"

# now include the dusk and dawn calculation
echo
while read desc jt ht ; do
  datestr=$(date --date="$(date +%F) $ht $ctz" +%R)
  printf "%14s %6s\n" $desc $datestr
done < /dev/shm/terrarium_times

# clean up timezone
TZ=$ctz
export TZ
