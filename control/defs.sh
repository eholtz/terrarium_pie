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

soll_tempecke_tag_min=25
soll_tempecke_tag_max=28

soll_tempdecke_tag_min=34
soll_tempdecke_tag_max=39

tagstart_licht=$(($(/root/bin/sunrise_sunset rise)))
nachtstart_licht=$(($(/root/bin/sunrise_sunset set)))
#tagstart_licht=1000
#nachtstart_licht=2000

brunnen_start=$(($tagstart_licht+1800))
brunnen_stop=$(($nachtstart_licht-1800))
brunnen_stop=0

tagstart_stein=$(($tagstart_licht+7200))
nachtstart_stein=$(($nachtstart_licht-7200))

#tagstart_ecke=$tagstart_licht
tagstart_ecke=$(($tagstart_licht+3600))
nachtstart_ecke=$(($nachtstart_licht-3600))

#stein_start=$(date --date "12:00" +%s)
#stein_stop=$(($stein_start+3600))
stein_start=0
stein_stop=0

regentodayfile="defs/regen_$(date +%F)"
if [ ! -e "$regentodayfile" ] ; then
  rm -f defs/regen_*
  touch $regentodayfile
  if [ $(($(date +%s) / 86400 % 3)) -eq 0 ] ; then
    echo $(($RANDOM % ($nachstart_licht-$tagstart_licht) )) > defs/regen
  else
    echo "0" > defs/regen
  fi
  cd defs
  /root/bin/calc_lightvalues &
fi

regendef=$(cat defs/regen || echo 1000)

if [ $regendef -ne 0 ] ; then
  regen_start=$(($tagstart_licht+$regendef))
  regen_stop=$(($regen_start+300))
else
  regen_start=0
  regen_stop=$regen_start
fi

#nebel_start=$(($nachtstart_licht+1800))
#nebel_stop=$(($nebel_start+3600))
nebel_start=0
nebel_stop=0

#currtime=$(TZ="Europe/Berlin" date +%H%M)
#currutc=$(date +%H%M)
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

#if [ $currtime -ge $brunnen_start ] && [ $currtime -lt $brunnen_stop ] ; then
#  brunnen_an=1
#fi

if [ $currtime -ge $stein_start ] && [ $currtime -le $stein_stop ] ; then
  stein_an=1
fi

if [ $currtime -ge $regen_start ] && [ $currtime -le $regen_stop ] ; then
  regen_an=1
fi

if [ $currtime -ge $nebel_start ] && [ $currtime -le $nebel_stop ] ; then
  nebel_an=1
fi

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
#echo -e "Strt Brunnen\t$brunnen_start\t$(date -d @$brunnen_start +%c)"
#echo -e "Stop Brunnen\t$brunnen_stop\t$(date -d @$brunnen_stop +%c)"
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
# [ $brunnen_an ] && echo "Der Brunnen ist an"
echo

