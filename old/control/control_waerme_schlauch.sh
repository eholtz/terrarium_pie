#!/bin/bash

#gpio pins:
# gpio -g write 17 1 => ausschalten

onf="schlauch.turned.on"
off="schlauch.turned.off"

currtime=$(date +%s)
turnedon=$currtime
turnedoff=0
[ -f $onf ] && turnedon=$(cat $onf)
[ -f $off ] && turnedoff=$(cat $off)

echo "Wärmeschlauch vor $(($currtime-$turnedon)) Sekunden angeschaltet."
echo "Wärmeschlauch vor $(($currtime-$turnedoff)) Sekunden ausgeschaltet."

if [ $temptuer -lt 21 ] ; then
  turnon 17 $onf
elif [ $temptuer -gt 21 ] ; then
  turnoff 17 $off
fi

