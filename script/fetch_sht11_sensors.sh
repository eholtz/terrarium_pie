#!/bin/bash

wd=$(dirname $0)
bindir="$wd/../bin/"

declare -A t
declare -A h

date +%s > /tmpfs/data_ts

for i in $(seq 1 3); do
	sudo $bindir/sensor$i > /tmpfs/data_sensor$i
	read ct ch < /tmpfs/data_sensor$i
	t[$i]=$ct
	h[$i]=$ch
done
timeout 10 rrdtool update /mnt/nfs/sensors.rrd N:${t[1]}:${h[1]}:${t[2]}:${h[2]}:${t[3]}:${h[3]}
timeout 10 cp /tmpfs/data_* /mnt/nfs/

