#!/bin/bash

# entry point for the complete terrarium control procedures

# first check if we have messed up time
if [ $(chronyc tracking | grep "System time" | awk '{print $4}' | cut -d '.' -f 1) -gt 5 ] ; then
  systemctl restart chrony
  sleep 2
  chronyc waitsync 3
fi

# now get all the definitions from config
source "$(readlink -f $(dirname $0)/../config/files.sh)"

runlog="$dir_log/runlog.$(date +%Y%m%d.%H%M%S)"

echo "Starting up @ $(date +"%T %Z") ... " > $runlog
echo "logfile is $runlog " >> $runlog

if [ $init -eq 1 ] ; then
  echo "Seems we have been rebooted or whatever, so init things ..." >> $runlog
  $dir_script/init.sh &>> $runlog
fi

echo "Read the daylight times ... " >> $runlog
source $dir_script/times_daylight.sh &>> $runlog

echo "Read the rain times ... " >> $runlog
source $dir_script/times_rain.sh &>> $runlog

echo "Read the sensors ... " >> $runlog
source $dir_script/last_sensor_data.sh &>> $runlog

echo "Control the light ... " >> $runlog
source $dir_script/control_light.sh &>> $runlog

echo "Control the spots ... " >> $runlog
source $dir_script/control_spots.sh &>> $runlog

echo "Switching the relais pins ..." >> $runlog
source $dir_script/switch_relais.sh &>> $runlog


[ -f $dir_log/lastlog ] && rm $dir_log/lastlog
ln -s $runlog $dir_log/lastlog
