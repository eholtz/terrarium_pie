#!/bin/bash

if [ ${temperature[${sensornameid["Ecke"]}]} -lt $soll_temp_ecke_nacht_min ]; then
  echo "Temp Ecke is below threshold $soll_temp_ecke_nacht_min => turn heating on"
  switchrelais[${relaisnamepin["Heizschlauch"]}]=1
elif [ ${temperature[${sensornameid["Ecke"]}]} -gt $soll_temp_ecke_nacht_max ]; then
  echo "Temp Ecke is above threshold $soll_temp_ecke_nacht_max => turn heating off"
  switchrelais[${relaisnamepin["Heizschlauch"]}]=0
fi

