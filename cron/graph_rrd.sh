#!/bin/bash

# let's do this in local timezone
TZ="Europe/Berlin"
export TZ

# nice colors for the temp/humidity
declare -A tmpcol
declare -A humcol
tmpcol[0]="ff0000"
tmpcol[1]="ff4444"
tmpcol[2]="ff8888"
tmpcol[3]="ffaaaa"
humcol[0]="0000ff"
humcol[1]="4444ff"
humcol[2]="8888ff"
humcol[3]="aaaaff"

# timespans with sorting
timespans="1_12h 2_7d 3_4w 4_1y"

# path for graphics
rrdg="/mnt/nfs/rrd/graphs/"
mkdir -p $rrdg

# path for sensors
rrds_sensors="/mnt/nfs/rrd/sensors/"

# names for sensors
declare -A sensornames
sensornames[23]="Decke"
sensornames[24]="Ecke"

# init execution file
echo >/dev/shm/rrdexec

for i in $timespans; do
  span=$(echo $i | cut -d '_' -f 2)
  defaultrrdoptions="--lazy --end now --start end-${span} --tabwidth 60 --width 1024"

  DEF=""
  VDEF=""
  GRAPH=""
  counter=0
  for sensor in $(ls $rrds_sensors); do
    DEF="$DEF DEF:t${sensor}=${rrds_sensors}/${sensor}:temperature:AVERAGE"
    VDEF="$VDEF VDEF:t${sensor}l=t${sensor},LAST"
    GRAPH="$GRAPH LINE1:t${sensor}#${tmpcol[$counter]}:\"${sensornames[${sensor}]}\t\" GPRINT:t${sensor}l:\"%2.1lf °C\l\""
    counter=$((counter + 1))
  done
  echo "timeout 10 rrdtool graph $rrdg/${i}_temperature.png $defaultrrdoptions --title \"Temperatur - ${span}\" $DEF $VDEF $GRAPH" >>/dev/shm/rrdexec

  DEF=""
  VDEF=""
  GRAPH=""
  counter=0
  for sensor in $(ls $rrds_sensors); do
    DEF="$DEF DEF:h${sensor}=${rrds_sensors}/${sensor}:humidity:AVERAGE"
    VDEF="$VDEF VDEF:h${sensor}l=h${sensor},LAST"
    GRAPH="$GRAPH LINE1:h${sensor}#${humcol[$counter]}:\"${sensornames[${sensor}]}\t\" GPRINT:h${sensor}l:\"%3.0lf %%\l\""
    counter=$((counter + 1))
  done
  echo "timeout 10 rrdtool graph $rrdg/${i}_humidity.png $defaultrrdoptions --title \"Luftfeuchtigkeit - ${span}\" $DEF $VDEF $GRAPH" >>/dev/shm/rrdexec
done

bash /dev/shm/rrdexec &>/dev/null
