#!/bin/bash

#gpio pins:
# gpio -g write 12 1 => spot stein ausschalten

onf="stein.turned.on"
off="stein.turned.off"

currtime=$(date +%s)
turnedon=$currtime
turnedoff=0
[ -f $onf ] && turnedon=$(cat $onf)
[ -f $off ] && turnedoff=$(cat $off)

echo "Wärmelampe Stein vor $(($currtime-$turnedon)) Sekunden angeschaltet."
echo "Wärmelampe Stein vor $(($currtime-$turnedoff)) Sekunden ausgeschaltet."

if [ $nacht_stein ] ; then
  turnoff 12 $off
  return 0
else

  # wenn der spot vor weniger als einer halben stunde ausgeschaltet wurde => nicht schalten
  if [ $(($currtime-$turnedoff)) -ge 1800 ] ; then
    if [ $stein_an ] ; then
      turnon 12 $onf
      return 0
    elif [ $temptuer -ge $soll_temptuer_tag_max ] || [ $tempecke -ge $soll_temptuer_tag_max ] || [ $tempdecke -ge $soll_tempdecke_tag_max ]; then
      turnoff 12 $off
      return 0
    elif [ $tempecke -lt $soll_temptuer_tag_min ] ; then
      turnon 12 $onf
      return 0
    fi
  else
    echo "Wärmelampe Stein wird nicht geschaltet => Minimum eine halbe Stunde aus!"
  fi

  # wenn der spot zwei stunden an war => ausschalten
  if [ $(($currtime-$turnedon)) -ge 7200 ]; then
    echo "Wärmelampe Stein war zwei Stunden an => ausschalten!"
    turnoff 12 $off
    return 0
  fi
fi
