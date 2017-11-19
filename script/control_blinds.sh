#!/bin/bash

# move 12 minutes
movetime_up=$((13*60))
movetime_down=$((11*60))

# so lange current > start daemmerung und current < ( start daemmerung + movetime )

if [ $epoch_current -ge $epoch_morgendaemmerung_start ] && [ $epoch_current -lt $(($epoch_morgendaemmerung_start+$movetime_up)) ] ; then
  echo "Roll up the blinds"
  gpio write ${motorpins[2]} 1
else
  gpio write ${motorpins[2]} 0
fi

# so lange current > ( stop daemmerung - movetime  ) und current < stop daemmerung

if [ $epoch_current -ge $(($epoch_abenddaemmerung_stop-$movetime_down)) ] && [ $epoch_current -lt $epoch_abenddaemmerung_stop ] ; then
  echo "Roll down the blinds"
  gpio write ${motorpins[1]} 1
else
  gpio write ${motorpins[1]} 0
fi

