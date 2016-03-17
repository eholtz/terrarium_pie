#!/bin/bash

#gpio pins:
# gpio -g write 13 1 => spot ecke ausschalten

onf="ecke.turned.on"
off="ecke.turned.off"

currtime=$(date +%s)
turnedon=$currtime
turnedoff=0
[ -f $onf ] && turnedon=$(cat $onf)
[ -f $off ] && turnedoff=$(cat $off)

echo "Wärmelampe Ecke vor $(($currtime-$turnedon)) Sekunden angeschaltet."
echo "Wärmelampe Ecke vor $(($currtime-$turnedoff)) Sekunden ausgeschaltet."

if [ $nacht_ecke ] ; then
  turnoff 13 $off
else

  # wenn der spot vor weniger als einer halben stunde ausgeschaltet wurde => nicht schalten
  if [ $(($currtime-$turnedoff)) -ge 1800 ] ; then
    if [ $temptuer -ge $soll_tempecke_tag_max ] || [ $tempecke -ge $soll_tempecke_tag_max ] || [ $tempdecke -ge $(($soll_tempdecke_tag_max-2)) ] ; then
      turnoff 13 $off
      return 0
    elif [ $temptuer -lt $soll_tempecke_tag_min ] ; then 
      turnon 13 $onf
      return 0
    fi
  else
    echo "Wärmelampe Ecke wird nicht geschaltet => Minimum eine halbe Stunde aus!"
  fi

  # wenn der spot zwei stunden an war => ausschalten
  if [ $(($currtime-$turnedon)) -ge 7200 ]; then
    echo "Wärmelampe Ecke war zwei Stunden an => ausschalten!"
    turnoff 13 $off
    return 0
  fi
fi
