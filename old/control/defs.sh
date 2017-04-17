#!/bin/bash

pin_tageslicht=8
pin_trafo=9
pin_spotstein=7
pin_spotecke=0
pin_heizschlauch=2
pin_kamera=3
pin_regenmaschine=12
pin_1=$pin_tageslicht
pin_2=$pin_trafo
pin_3=$pin_spotstein
pin_4=$pin_spotecke
pin_5=$pin_heizschlauch
pin_6=$pin_kamera
pin_7=$pin_regenmaschine
pin_8=14

scriptdir="$(readlink -f $(dirname $0))"
definitionsdir="/tmp/terracontrol/"
timesfile="${definitionsdir}/times"
epochfile="${definitionsdir}/times_epoch"
timesbinary="$scriptdir/../bin/timecontrol"

mkdir -p ${definitionsdir}

# be sure to be in utc mode
TZ="UTC"
export TZ
currtime=$(date +%s)

# we may had a restart, then we have no control files
# if no files are there => recreate
[ ! -f $timesfile ] && cd $(dirname $timesfile) && $timesbinary
if [ ! -f $epochfile ]; then
  read msh tlh nlh ash tah toh < $timesfile
  ms=$(date -d $msh +%s)
  tl=$(date -d $tlh +%s)
  nl=$(date -d $nlh +%s)
  as=$(date -d $ash +%s)
  ta=$(date -d $tah +%s)
  to=$(date -d $toh +%s)
  echo "$ms $tl $nl $as $ta $to" > $epochfile
  
  # set all write pins to write mode
  gpio mode $pin_1 out
  gpio mode $pin_2 out
  gpio mode $pin_3 out
  gpio mode $pin_4 out
  gpio mode $pin_5 out
  gpio mode $pin_6 out
  gpio mode $pin_7 out
  gpio mode $pin_8 out

  # zero all pins
  gpio write $pin_1 0
  gpio write $pin_2 0
  gpio write $pin_3 0
  gpio write $pin_4 0
  gpio write $pin_5 0
  gpio write $pin_6 0
  gpio write $pin_7 0
  gpio write $pin_8 0
fi
cd $scriptdir

# now we need the times when sun has risen und when the sun will set
read morgendaemmerung_start tagstart_licht nachtstart_licht abenddaemmerung_stop tagstart tagstop < $epochfile

# calculate the times for switching other features
# based on the day start
tagstart_stein=$(($tagstart_licht+1200))
nachtstart_stein=$(($nachtstart_licht-1200))

tagstart_ecke=$(($tagstart_licht+3600))
nachtstart_ecke=$(($nachtstart_licht-3600))

# check if today should be a rainy day or not
# this is also the "once a day" control for
# recalculating daystart/daystop

regentodayfile="${definitionsdir}/regen_$(date +%F)"
regendauerfile="${definitionsdir}/regen_dauer"
regenzeitfile="${definitionsdir}/regen_zeit"

if [ ! -e "$regentodayfile" ] ; then
  # clean up definitions dir
  rm -f "${definitionsdir}/*"
  touch $regentodayfile
  # it will rain about once every four days
  if [ $(($RANDOM % 4)) -eq 0 ] ; then
    echo $(($RANDOM % ($nachstart_licht-$tagstart_licht) )) > $regenzeitfile
    echo $((($RANDOM % 15)*60+300)) > $regendauerfile
  else
    echo "0" > $regenzeitfile
    echo "0" > $regendauerfile
  fi
fi
cd $scriptdir

regendef=$(cat $regenzeitfile || echo 1000)
regen_dauer=$(cat $regendauerfile || echo 600)

if [ $regendef -ne 0 ] ; then
  regen_start=$(($tagstart_licht+$regendef))
  regen_stop=$(($regen_start+$regen_dauer))
else
  regen_start=0
  regen_stop=$regen_start
fi

#tempecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
#temptuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
#tempdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
#
#feuchtecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
#feuchttuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
#feuchtdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)

#echo "currtime $currtime"
# den waermelampen zeit zum abkühlen vor dem regen geben
# sonst können sie schon mal kaputt gehen
# und auch danach noch ein bisschen zeit zum wasser ablaufen lassen geben
#if [ $regen_start -ne 0 ] && [ $currtime -gt $(($regen_start-1600)) ] && [ $currtime -lt $(($regen_stop+1600)) ]; then
#  nacht_stein=1
#  nacht_ecke=1
#fi

#if [ $currtime -ge $nachtstart_licht ] || [ $currtime -lt $tagstart_licht ] ; then
#  nacht_licht=1
#else
#  tag_licht=1
#fi
#
#if [ $currtime -ge $nachtstart_stein ] || [ $currtime -lt $tagstart_stein ] ; then
#  nacht_stein=1
#else
#  tag_stein=1
#fi
#
#if [ $currtime -ge $nachtstart_ecke ] || [ $currtime -lt $tagstart_ecke ] ; then
#  nacht_ecke=1
#else
#  tag_ecke=1
#fi
#
#if [ $currtime -ge $regen_start ] && [ $currtime -le $regen_stop ] && [ $((($currtime/60) % 3)) -ne 0 ] ; then
#  regen_an=1
#fi
#
## temporary solution for heating quarantine box
##if [ $(($(date +%H)%2)) -eq 0 ] && [ $tag_stein ] ; then
##  stein_an=1
##fi
#

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
#echo "Messwerte"
#echo -e "\t\tDecke\tTuer\tEcke"
#echo -e "Temperatur\t$tempdecke\t$temptuer\t$tempecke"
#echo -e "Luftfeuchte\t$feuchtdecke\t$feuchttuer\t$feuchtecke"
#echo
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
#echo

TZ="UTC"
export TZ
