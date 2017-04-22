#!/bin/bash

# keep the spots turned off half an hour before and after the rain
# to avoid cracking the bulb
spot_timeout=1600

if [ $epoch_rain_start -gt 0 ]; then
  echo "Today it will rain ..."
  if [ $(($epoch_rain_start-$spot_timeout)) -lt $epoch_current ] && [ $(($epoch_rain_stop+$spot_timeout)) -gt $epoch_current ]; then
    echo "It will rain or has been raining within the next $spot_timeout seconds, so turn off the spots"
    switchrelais[${relaisnamepin["Spot Stein"]}]=0
    switchrelais[${relaisnamepin["Spot Ecke"]}]=0
  fi
  if [ $epoch_current -ge $epoch_rain_start ] && [ $epoch_current -le $epoch_rain_stop ]; then
    switchrelais[${relaisnamepin["Regenmaschine"]}]=1
  else
    switchrelais[${relaisnamepin["Regenmaschine"]}]=0
  fi
  # This trick turns the rainmachine off for one minute every three minutes
  # It is needed becaus the rain machine will stop after about 3 three minutes
  # and only restart 15 minutes later
  if [ $((($epoch_current/60) % 3)) -eq 0 ] ; then
    switchrelais[${relaisnamepin["Regenmaschine"]}]=0
  fi
else
  echo "No rain today ..."
fi
