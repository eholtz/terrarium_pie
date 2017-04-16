#!/bin/bash

# this is meant to be sourced for every script that runs
# for the control of the terrarium

dir_tmp="/tmp/terra_control/"
dir_base=$(dirname $(readlink -f $(dirname $0)))
dir_config="$dir_base/config/"
dir_script="$dir_base/script/"
dir_bin="$dir_base/bin/"
dir_log="$dir_tmp/log/"
dir_rrd="$dir_tmp/rrd/"
dir_html="/var/www/terrarium/"

[ ! -d $dir_tmp ] && mkdir -p $dir_tmp && init=1
[ ! -d $dir_log ] && mkdir -p $dir_log && init=1
[ ! -d $dir_rrd ] && mkdir -p $dir_rrd && init=1

rrd_gpio="$dir_rrd/gpio"
rrd_sensor="$dir_rrd/sensor"

declare -A sensors
declare -A sensornames
sensors[1]=22
sensors[2]=24
sensorname[22]="Ecke"
sensorname[24]="Deckel"


