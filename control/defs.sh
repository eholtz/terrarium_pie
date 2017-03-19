#!/bin/bash

#gpio pins:
# gpio -g write 11 1 => licht ausschalten
# gpio -g write 12 1 => spot stein ausschalten
# gpio -g write 13 1 => spot ecke ausschalten
# gpio -g write 15 1 => beregnung ausschalten
# gpio -g write 16 1 => vernebler/geckocam ausschalten
# gpio -g write 17 1 => heizschlauch ausschalten
# gpio -g write 23 1 => umlaufpumpe
# gpio -g write 24 1 => pumpe terrarium => beregnung 
# zweiter relaisblock
# gpio -g write 5 1 => brunnen
# gpio -g write 26 1 => sonnenaufgang
# gpio -g write 26 1 => defekt?


soll_temptuer_tag_min=25
soll_temptuer_tag_max=27

#sommer
soll_tempecke_tag_min=25

#winter
soll_tempecke_tag_min=22
soll_tempecke_tag_max=28


soll_tempdecke_tag_min=34

#sommer
soll_tempdecke_tag_max=39

#winter
soll_tempdecke_tag_max=36

# we may had a restart, then we have no control files
# if no files are there => recreate
[ ! -f /tmpfs/times ] && cd /tmpfs/ && /root/bin/timecontrol
if [ ! -f /tmpfs/times_epoch ]; then
  read msh tlh nlh ash tah toh < /tmpfs/times
  ms=$(date -d $msh +%s)
  tl=$(date -d $tlh +%s)
  nl=$(date -d $nlh +%s)
  as=$(date -d $ash +%s)
  ta=$(date -d $tah +%s)
  to=$(date -d $toh +%s)
  echo "$ms $tl $nl $as $ta $to" > /tmpfs/times_epoch
fi
cd $dir

# now we need the times when sun has risen und when the sun will set
read morgendaemmerung_start tagstart_licht nachtstart_licht abenddaemmerung_stop tagstart tagstop < /tmpfs/times_epoch

# calculate the times for switching other features
# based on the day start
tagstart_stein=$(($tagstart_licht+1200))
nachtstart_stein=$(($nachtstart_licht-1200))

tagstart_ecke=$(($tagstart_licht+3600))
nachtstart_ecke=$(($nachtstart_licht-3600))

# check if today should be a rainy day or not
# this is also the "once a day" control for
# recalculating daystart/daystop

regentodayfile="defs/regen_$(date +%F)"
if [ ! -e "$regentodayfile" ] ; then
  rm -f defs/regen_*
  touch $regentodayfile
  # it will rain about once every four days
  if [ $(($RANDOM / 86400 % 4)) -eq 0 ] ; then
    echo $(($RANDOM % ($nachstart_licht-$tagstart_licht) )) > defs/regen
    echo $((($RANDOM % 15)*60+300)) > defs/regen_dauer
  else
    echo "0" > defs/regen
  fi
  ### new control files every day :-)
  cd /tmpfs
  rm -f /tmpfs/times*
fi
cd $dir

regendef=$(cat defs/regen || echo 1000)
regen_dauer=$(cat defs/regen_dauer || echo 600)

if [ $regendef -ne 0 ] ; then
  regen_start=$(($tagstart_licht+$regendef))
  regen_stop=$(($regen_start+$regen_dauer))
else
  regen_start=0
  regen_stop=$regen_start
fi

currtime=$(date +%s)

tempecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
temptuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
tempdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)

feuchtecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
feuchttuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
feuchtdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)

# den waermelampen zeit zum abkühlen vor dem regen geben
# sonst können sie schon mal kaputt gehen
# und auch danach noch ein bisschen zeit zum wasser ablaufen lassen geben
if [ $regen_start -ne 0 ] && [ $(date +%s) -gt $(($regen_start-1600)) ] && [ $(date +%s) -lt $(($regen_stop+1600)) ]; then
  nacht_stein=1
  nacht_ecke=1
fi

if [ $currtime -ge $nachtstart_licht ] || [ $currtime -lt $tagstart_licht ] ; then
  nacht_licht=1
else
  tag_licht=1
fi

if [ $currtime -ge $nachtstart_stein ] || [ $currtime -lt $tagstart_stein ] ; then
  nacht_stein=1
else
  tag_stein=1
fi

if [ $currtime -ge $nachtstart_ecke ] || [ $currtime -lt $tagstart_ecke ] ; then
  nacht_ecke=1
else
  tag_ecke=1
fi

if [ $currtime -ge $regen_start ] && [ $currtime -le $regen_stop ] && [ $((($currtime/60) % 3)) -ne 0 ] ; then
  regen_an=1
fi

# temporary solution for heating quarantine box
#if [ $(($(date +%H)%2)) -eq 0 ] && [ $tag_stein ] ; then
#  stein_an=1
#fi

TZ="Europe/Berlin"
export TZ

echo -e "Tag Start\t$tagstart_licht\t$(date -d @$tagstart_licht +%c)"
echo -e "Tag Stop\t$nachtstart_licht\t$(date -d @$nachtstart_licht +%c)"
echo -e "Strt Ecklampe\t$tagstart_ecke\t$(date -d @$tagstart_ecke +%c)"
echo -e "Stop Ecklampe\t$nachtstart_ecke\t$(date -d @$nachtstart_ecke +%c)"
echo -e "Strt Steinlampe\t$tagstart_stein\t$(date -d @$tagstart_stein +%c)"
echo -e "Stop Steinlampe\t$nachtstart_stein\t$(date -d @$nachtstart_stein +%c)"
echo -e "Strt Regen\t$regen_start\t$(date -d @$regen_start +%c)"
echo -e "Stop Regen\t$regen_stop\t$(date -d @$regen_stop +%c)"
echo
echo "Messwerte"
echo -e "\t\tDecke\tTuer\tEcke"
echo -e "Temperatur\t$tempdecke\t$temptuer\t$tempecke"
echo -e "Luftfeuchte\t$feuchtdecke\t$feuchttuer\t$feuchtecke"
echo
[ $nacht_licht ] && echo "Es ist Nacht"
[ $tag_licht ] && echo "Es ist Tag"
echo
[ $nacht_ecke ] && echo "Wärmelampe Ecke wird nicht geschaltet"
[ $tag_ecke ] && echo "Wärmelampe Ecke wird geschaltet"
[ $nacht_stein ] && echo "Wärmelampe Stein wird nicht geschaltet"
[ $tag_stein ] && echo "Wärmelampe Stein wird geschaltet"
echo
[ $stein_an ] && echo "Wärmelampe Stein an"
[ $regen_an ] && echo "Es regnet"
echo

TZ="UTC"
export TZ
