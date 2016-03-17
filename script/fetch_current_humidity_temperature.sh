#!/bin/bash

ghe="/root/bin/get_hum_tem"

sensors="2 3 7"

for i in $sensors; do
	res=$(timeout 10 $ghe $i)
	hum=$(echo $res | awk '{print $1}')
	tem=$(echo $res | awk '{print $2}')
	if [ -n "$hum" ] && [ -n "$tem" ]; then
		rrdtool update /root/rrd/ht-sensor-${i} N:$hum:$tem
	fi
#	echo "hum $hum tem $tem"
done
