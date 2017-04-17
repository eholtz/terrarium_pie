#!/bin/bash

#gpio pins:
# gpio -g write 11 1 => licht ausschalten
# gpio -g write 12 1 => spot stein ausschalten
# gpio -g write 13 1 => spot ecke ausschalten
# gpio -g write 15 1 => beregnung ausschalten
# gpio -g write 16 1 => vernebler ausschalten

# rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1

soll_tempmitte_tag_min=24
soll_tempmitte_tag_max=27
soll_tempdecke_tag_min=30
soll_tempdecke_tag_max=33

tagstart=1000
nachstart=2000

tempdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
temptuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)
tempecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $3}' | cut -d '.' -f 1)

feuchtdecke=$(rrdtool lastupdate /root/rrd/ht-sensor-2 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
feuchttuer=$(rrdtool lastupdate /root/rrd/ht-sensor-3 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)
feuchtecke=$(rrdtool lastupdate /root/rrd/ht-sensor-7 | tail -n 1 | awk '{print $2}' | cut -d '.' -f 1)

if [ $(TZ="Europe/Berlin" date +%H%M) -ge $nachstart ] || [ $(TZ="Europe/Berlin" date +%H%M) -lt $tagstart ] ; then
	nacht=1
else
	tag=1
fi

echo "Temperatur"
echo $tempdecke $temptuer $tempecke
echo "Luftfeuchtigkeit"
echo $feuchtdecke $feuchttuer $feuchtecke
[ $nacht ] && echo "Nacht"
[ $tag ] && echo "Tag"


if [ $nacht ] ; then
	gpio -g write 11 1
	gpio -g write 12 1
	gpio -g write 13 1
else
	gpio -g write 11 0
	if [ $temptuer -ge $soll_tempmitte_tag_max ] || [ $tempecke -ge $soll_tempmitte_tag_max ] ; then
		gpio -g write 13 1
	elif [ $tempdecke -ge $soll_tempdecke_tag_max ] ; then
		gpio -g write 13 1
		gpio -g write 12 1
	elif [ $temptuer -le $soll_tempmitte_tag_min ] || [ $tempecke -le $soll_tempmitte_tag_min ] || [ $tempdecke -le $soll_tempdecke_tag_min ]; then
		gpio -g write 13 0
		gpio -g write 12 0
	fi
fi

date > lastrun
