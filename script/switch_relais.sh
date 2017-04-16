#!/bin/bash

for i in "${!switchrelais[@]}" ; do
  echo "Switching pin ${relaispins[$i]} (${relaispinname[$i]}) to ${switchrelais[$i]}"
  gpio write ${relaispins[$i]} ${switchrelais[$i]}
done
