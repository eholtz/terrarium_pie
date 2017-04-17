#!/bin/bash

# be sure to be in utc mode
TZ="UTC"
export TZ

if [ $(date +%H) -eq 12 ] ; then
  echo "It's noon => turn Spot Stein on"
  switchrelais[${relaisnamepin["Spot Stein"]}]=1
else
  echo "It's not noon => turn Spot Stein off"
  switchrelais[${relaisnamepin["Spot Stein"]}]=0
fi

if [ ${temperature[${sensornameid["Ecke"]}]} -lt $soll_temp_ecke_tag_min ]; then
  echo "Temp Ecke is below threshold $soll_temp_ecke_min => turn Spot Ecke on"
  switchrelais[${relaisnamepin["Spot Ecke"]}]=1
elif [ ${temperature[${sensornameid["Ecke"]}]} -gt $soll_temp_ecke_tag_max ]; then
  echo "Temp Ecke is above threshold $soll_temp_ecke_max => turn Spot Ecke off"
  switchrelais[${relaisnamepin["Spot Ecke"]}]=0
fi

if [ ${temperature[${sensornameid["Deckel"]}]} -gt $soll_temp_deckel_tag_max ] ; then
  echo "Temp Deckel reached maximum of 40°C => turn everything off"
  switchrelais[${relaisnamepin["Spot Stein"]}]=0
  switchrelais[${relaisnamepin["Spot Ecke"]}]=0
fi

if [ $epoch_current -le $epoch_tageslicht_start ] ; then
  echo "It is too early => turn off spots"  
  switchrelais[${relaisnamepin["Spot Stein"]}]=0
  switchrelais[${relaisnamepin["Spot Ecke"]}]=0
fi

if [ $epoch_current -ge $epoch_tageslicht_stop ] ; then
  echo "It is too late => turn off spots"
  switchrelais[${relaisnamepin["Spot Stein"]}]=0
  switchrelais[${relaisnamepin["Spot Ecke"]}]=0
fi

