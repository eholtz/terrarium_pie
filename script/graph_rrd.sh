#!/bin/bash

cwd=$(pwd)

cd /tmpfs/
rrdpath="/mnt/nfs/"
output="/var/www/html/rrd/"

sensorfile="$rrdpath/sensors.rrd"

for i in 2_12h 4_2d 5_7d ; do
span=$(echo $i | cut -d '_' -f 2)

TZ="Europe/Berlin"
export TZ

lastvalue=$(rrdtool last $rrdpath/sensors.rrd)

timeout 10 rrdtool graph $output/${i}_humidity.png --lazy --end $lastvalue --start end-${span} --width 1024 \
        --title "Luftfeuchtigkeit - ${span}" \
        DEF:h1=$sensorfile:h1:AVERAGE \
        DEF:h2=$sensorfile:h2:AVERAGE \
        DEF:h3=$sensorfile:h3:AVERAGE \
        VDEF:h1l=h1,LAST \
        VDEF:h2l=h2,LAST \
        VDEF:h3l=h3,LAST \
        LINE1:h1#0099ff:"Sensor 1 / Boden\t" \
        GPRINT:h1l:"%2.1lf %%\l" \
        LINE1:h3#9900ff:"Sensor 3 / Mitte\t" \
        GPRINT:h3l:"%2.1lf %%\l" \
        LINE1:h2#0000ff:"Sensor 2 / Decke\t" \
        GPRINT:h2l:"%2.1lf %%\l"

timeout 10 rrdtool graph $output/${i}_temperature.png --lazy --end $lastvalue --start end-${span} --width 1024 \
        --title "Temperatur - ${span}" \
        DEF:t1=$sensorfile:t1:AVERAGE \
        DEF:t2=$sensorfile:t2:AVERAGE \
        DEF:t3=$sensorfile:t3:AVERAGE \
        VDEF:t1l=t1,LAST \
        VDEF:t2l=t2,LAST \
        VDEF:t3l=t3,LAST \
        LINE1:t1#ff9900:"Sensor 1 / Boden\t" \
        GPRINT:t1l:"%2.1lf °C\l" \
        LINE1:t3#ff0099:"Sensor 3 / Mitte\t" \
        GPRINT:t3l:"%2.1lf °C\l" \
        LINE1:t2#ff0000:"Sensor 2 / Decke\t" \
        GPRINT:t2l:"%2.1lf °C\l"

done

cd $cwd
