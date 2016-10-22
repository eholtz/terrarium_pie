#!/bin/bash

myp=$(readlink -f $(dirname $0))

#gpio pins:
# gpio -g write 20 1 => hqi lampe 
# gpio -g write 21 1 => neonroeren
# gpio -g write 26 1 => beide luefter
# gpio -g write 16 1 => led

#
#soll_temptuer_tag_min=25
#soll_temptuer_tag_max=27
#
#soll_tempecke_tag_min=25
#soll_tempecke_tag_max=28
#
#soll_tempdecke_tag_min=34
#soll_tempdecke_tag_max=39
#

# we may had a restart, then we have no control files
# if no files are there => recreate
[ ! -f /tmpfs/times ] && cd /tmpfs/ && $myp/../bin/timecontrol
if [ ! -f /tmpfs/times_epoch ]; then
  for i in 16 20 21 26 22 23 24 ; do
    gpio -g mode $i out
    gpio -g write $i 0
  done
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
#tagstart_stein=$(($tagstart_licht+1200))
#nachtstart_stein=$(($nachtstart_licht-1200))

#tagstart_ecke=$(($tagstart_licht+3600))
#nachtstart_ecke=$(($nachtstart_licht-3600))

# check if today should be a rainy day or not
# this is also the "once a day" control for
# recalculating daystart/daystop

#regentodayfile="defs/regen_$(date +%F)"
#if [ ! -e "$regentodayfile" ] ; then
#  rm -f defs/regen_*
#  touch $regentodayfile
#  # it will rain once every three days
#  if [ $(($(date +%s) / 86400 % 3)) -eq 0 ] ; then
#    echo $(($RANDOM % ($nachstart_licht-$tagstart_licht) )) > defs/regen
#  else
#    echo "0" > defs/regen
#  fi
#  ### new control files every day :-)
#  cd /tmpfs
#  rm -f /tmpfs/times*
#fi
#cd $dir
#
#regendef=$(cat defs/regen || echo 1000)

#if [ $regendef -ne 0 ] ; then
#  regen_start=$(($tagstart_licht+$regendef))
#  regen_stop=$(($regen_start+600))
#else
#  regen_start=0
#  regen_stop=$regen_start
#fi
#

currtime=$(date +%s)

#tempecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
#temptuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
#tempdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)

#feuchtecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
#feuchttuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
#feuchtdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)

# den waermelampen zeit zum abkühlen vor dem regen geben
# sonst können sie schon mal kaputt gehen
# und auch danach noch ein bisschen zeit zum wasser ablaufen lassen geben
#if [ $regen_start -ne 0 ] && [ $(date +%s) -gt $(($regen_start-1600)) ] && [ $(date +%s) -lt $(($regen_stop+1600)) ]; then
#  nacht_stein=1
#  nacht_ecke=1
#fi

if [ $currtime -ge $(($nachtstart_licht)) ] || [ $currtime -lt $(($tagstart_licht)) ] ; then
    sun_off=1
else
    sun_on=1
fi

if [ $(($(date +%k) % 2)) -eq 0 ] ; then
    unset sun_on
    sun_off=1
fi

if [ $currtime -lt $morgendaemmerung_start ] || [ $currtime -ge $abenddaemmerung_stop ] ; then
    light_off=1
else
    light_on=1
fi

# morgendaemmerung_start tagstart_licht nachtstart_licht abenddaemmerung_stop

#if [ $currtime -ge $nachtstart_licht ] || [ $currtime -lt $tagstart_licht ] ; then
#  nacht_licht=1
#else
#  tag_licht=1
#fi

#if [ $currtime -ge $nachtstart_stein ] || [ $currtime -lt $tagstart_stein ] ; then
#  nacht_stein=1
#else
#  tag_stein=1
#fi

#if [ $currtime -ge $nachtstart_ecke ] || [ $currtime -lt $tagstart_ecke ] ; then
#  nacht_ecke=1
#else
#  tag_ecke=1
#fi

#if [ $currtime -ge $regen_start ] && [ $currtime -le $regen_stop ] && [ $(($currtime % 3)) -ne 0 ] ; then
#  regen_an=1
#fi

#if [ $(($(date +%H)%2)) -eq 0 ] && [ $tag_stein ] ; then
#  stein_an=1
#fi

TZ="Europe/Berlin"
export TZ

echo -e "Tag Start\t$tagstart_licht\t$(date -d @$tagstart_licht +%c)"
echo -e "Tag Stop\t$nachtstart_licht\t$(date -d @$nachtstart_licht +%c)"
echo -e "Daemmerung Strt\t$morgendaemmerung_start\t$(date -d @$morgendaemmerung_start +%c)"
echo -e "Daemmerung Stop\t$abenddaemmerung_stop\t$(date -d @$abenddaemmerung_stop +%c)"
#echo -e "Strt Ecklampe\t$tagstart_ecke\t$(date -d @$tagstart_ecke +%c)"
#echo -e "Stop Ecklampe\t$nachtstart_ecke\t$(date -d @$nachtstart_ecke +%c)"
#echo -e "Strt Steinlampe\t$tagstart_stein\t$(date -d @$tagstart_stein +%c)"
#echo -e "Stop Steinlampe\t$nachtstart_stein\t$(date -d @$nachtstart_stein +%c)"
#echo -e "Strt Regen\t$regen_start\t$(date -d @$regen_start +%c)"
#echo -e "Stop Regen\t$regen_stop\t$(date -d @$regen_stop +%c)"
#echo
#echo "Messwerte"
#echo -e "\t\tDecke\tTuer\tEcke"
#echo -e "Temperatur\t$tempdecke\t$temptuer\t$tempecke"
#echo -e "Luftfeuchte\t$feuchtdecke\t$feuchttuer\t$feuchtecke"
#echo
[ $light_on ] && echo "Licht (T5) an"
[ $sun_on ] && echo "HQI an"
#[ $nacht_licht ] && echo "Es ist Nacht"
#[ $tag_licht ] && echo "Es ist Tag"
#echo
#[ $nacht_ecke ] && echo "Wärmelampe Ecke wird nicht geschaltet"
#[ $tag_ecke ] && echo "Wärmelampe Ecke wird geschaltet"
#[ $nacht_stein ] && echo "Wärmelampe Stein wird nicht geschaltet"
#[ $tag_stein ] && echo "Wärmelampe Stein wird geschaltet"
#echo
#[ $stein_an ] && echo "Wärmelampe Stein an"
#[ $regen_an ] && echo "Es regnet"
echo

TZ="UTC"
export TZ
