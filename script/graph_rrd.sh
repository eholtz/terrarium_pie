#!/bin/bash

source "$(readlink -f $(dirname $0)/../config/files.sh)"

find $dir_html -exec chown www-data:www-data {} \; &> /dev/null
find $dir_html -type d -exec chmod 755 {} \; &> /dev/null
find $dir_html -type f -exec chmod 644 {} \; &> /dev/null

# let's do this in local timezone
TZ="Europe/Berlin"
export TZ

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

for i in 1_12h 2_7d 3_4w 4_1y ; do
  span=$(echo $i | cut -d '_' -f 2)
  lastvalue=$(rrdtool last $rrd_gpio)

  DEF=""
  VDEF=""
  GRAPH=""
  counter=0
  for s in "${!sensoridname[@]}" ; do
    DEF="$DEF DEF:v${s}=${rrd_sensor}_${sensors[$s]}:temperature:AVERAGE"
    VDEF="$VDEF VDEF:v${s}l=v${s},LAST"
    GRAPH="$GRAPH LINE1:v${s}#${tmpcol[$counter]}:\"${sensoridname[$s]}\t\" GPRINT:v${s}l:\"%2.1lf %%\l\""
    counter=$(($counter+1))
  done
  echo "timeout 10 rrdtool graph $dir_html/${i}_temperature.png --lazy --end $lastvalue --start end-${span} --width 1024 --title \"Temperatur - ${span}\" $DEF $VDEF $GRAPH" > $dir_volatile/rrd_execute
  bash $dir_volatile/rrd_execute
  cat $dir_volatile/rrd_execute

  DEF=""
  VDEF=""
  GRAPH=""
  counter=0
  for s in "${!sensoridname[@]}" ; do
    DEF="$DEF DEF:v${s}=${rrd_sensor}_${sensors[$s]}:humidity:AVERAGE"
    VDEF="$VDEF VDEF:v${s}l=v${s},LAST"
    GRAPH="$GRAPH LINE1:v${s}#${humcol[$counter]}:\"${sensoridname[$s]}\t\" GPRINT:v${s}l:\"%2.1lf %%\l\""
    counter=$(($counter+1))
  done
  echo "timeout 10 rrdtool graph $dir_html/${i}_humidity.png --lazy --end $lastvalue --start end-${span} --width 1024 --title \"Luftfeuchtigkeit - ${span}\" $DEF $VDEF $GRAPH" > $dir_volatile/rrd_execute
  bash $dir_volatile/rrd_execute
  cat $dir_volatile/rrd_execute

done

echo "<head><title></title><body>" > $dir_html/index.html
for image in $(find $dir_html -maxdepth 1 -iname "*.png" | sort -u) ; do
echo "<br /><img src=\"$(basename $image)\">" >> $dir_html/index.html
done 
echo "</body></html>" >> $dir_html/index.html

