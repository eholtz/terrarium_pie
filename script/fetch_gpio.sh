#!/bin/bash

declare -A gpiodata

for i in $(seq 0 31) ; do
	gpiodata[$i]=$(gpio -g read $i)
#	echo $i
# rrdtool update /root/rrd/ht-sensor-${i} N:$hum:$tem
done

#echo ${gpiodata[11]} ${gpiodata[12]} ${gpiodata[13]} ${gpiodata[14]} ${gpiodata[15]} ${gpiodata[16]} ${gpiodata[17]} ${gpiodata[18]}
rrdtool update /root/rrd/gpio N:${gpiodata[0]}:${gpiodata[1]}:${gpiodata[2]}:${gpiodata[3]}:${gpiodata[4]}:${gpiodata[5]}:${gpiodata[6]}:${gpiodata[7]}:${gpiodata[8]}:${gpiodata[9]}:${gpiodata[10]}:${gpiodata[11]}:${gpiodata[12]}:${gpiodata[13]}:${gpiodata[14]}:${gpiodata[15]}:${gpiodata[16]}:${gpiodata[17]}:${gpiodata[18]}:${gpiodata[19]}:${gpiodata[20]}:${gpiodata[21]}:${gpiodata[22]}:${gpiodata[23]}:${gpiodata[24]}:${gpiodata[25]}:${gpiodata[26]}:${gpiodata[27]}:${gpiodata[28]}:${gpiodata[29]}:${gpiodata[30]}:${gpiodata[31]}

