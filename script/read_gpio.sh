#!/bin/bash

declare -A gpiodata

if [ ! -f $rrd_gpio ]; then
  # every minute
  # keep 1 minute step for one day
  # keep 5 minutes step for 63 days
  # keep 1 hour step for a bit more than two years
  rrdtool create $rrd_gpio --start now-1d --step 60 \
    DS:pin0:GAUGE:120:0:1 \
    DS:pin1:GAUGE:120:0:1 \
    DS:pin2:GAUGE:120:0:1 \
    DS:pin3:GAUGE:120:0:1 \
    DS:pin4:GAUGE:120:0:1 \
    DS:pin5:GAUGE:120:0:1 \
    DS:pin6:GAUGE:120:0:1 \
    DS:pin7:GAUGE:120:0:1 \
    DS:pin8:GAUGE:120:0:1 \
    DS:pin9:GAUGE:120:0:1 \
    DS:pin10:GAUGE:120:0:1 \
    DS:pin11:GAUGE:120:0:1 \
    DS:pin12:GAUGE:120:0:1 \
    DS:pin13:GAUGE:120:0:1 \
    DS:pin14:GAUGE:120:0:1 \
    DS:pin15:GAUGE:120:0:1 \
    DS:pin16:GAUGE:120:0:1 \
    DS:pin17:GAUGE:120:0:1 \
    DS:pin18:GAUGE:120:0:1 \
    DS:pin19:GAUGE:120:0:1 \
    DS:pin20:GAUGE:120:0:1 \
    DS:pin21:GAUGE:120:0:1 \
    DS:pin22:GAUGE:120:0:1 \
    DS:pin23:GAUGE:120:0:1 \
    DS:pin24:GAUGE:120:0:1 \
    DS:pin25:GAUGE:120:0:1 \
    DS:pin26:GAUGE:120:0:1 \
    DS:pin27:GAUGE:120:0:1 \
    DS:pin28:GAUGE:120:0:1 \
    DS:pin29:GAUGE:120:0:1 \
    DS:pin30:GAUGE:120:0:1 \
    DS:pin31:GAUGE:120:0:1 \
    RRA:AVERAGE:0.5:1:1440 RRA:AVERAGE:0.1:5:18000 RRA:AVERAGE:0.1:60:18000

fi

for i in $(seq 0 31) ; do
	gpiodata[$i]=$(timeout 1 gpio -g read $i)
done

timeout 10 rrdtool update $rrd_gpio N:${gpiodata[0]}:${gpiodata[1]}:${gpiodata[2]}:${gpiodata[3]}:${gpiodata[4]}:${gpiodata[5]}:${gpiodata[6]}:${gpiodata[7]}:${gpiodata[8]}:${gpiodata[9]}:${gpiodata[10]}:${gpiodata[11]}:${gpiodata[12]}:${gpiodata[13]}:${gpiodata[14]}:${gpiodata[15]}:${gpiodata[16]}:${gpiodata[17]}:${gpiodata[18]}:${gpiodata[19]}:${gpiodata[20]}:${gpiodata[21]}:${gpiodata[22]}:${gpiodata[23]}:${gpiodata[24]}:${gpiodata[25]}:${gpiodata[26]}:${gpiodata[27]}:${gpiodata[28]}:${gpiodata[29]}:${gpiodata[30]}:${gpiodata[31]}

