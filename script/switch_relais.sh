#!/bin/bash

for i in "${!switchrelais[@]}" ; do
  echo "Switching pin $i (${relaispinname[$i]}) to ${switchrelais[$i]}"
  gpio write $i ${switchrelais[$i]}
done
