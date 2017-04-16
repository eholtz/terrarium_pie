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
dir_volatile="$dir_tmp/volatile/"
dir_html="/var/www/terrarium/"
dir_backup="/mnt/nfs/terrarium/"

init=0
[ ! -d $dir_tmp ] && mkdir -p $dir_tmp && init=1
[ ! -d $dir_log ] && mkdir -p $dir_log && init=1
[ ! -d $dir_rrd ] && mkdir -p $dir_rrd && init=1
[ ! -d $dir_volatile ] && mkdir -p $dir_volatile

rrd_gpio="$dir_rrd/gpio"
rrd_sensor="$dir_rrd/sensor"

declare -A sensors
declare -A sensornames
sensors[1]=22
sensors[2]=24
sensorname[1]="Ecke"
sensorname[2]="Deckel"

declare -A relaispins
declare -A relaispinnames
relaispins[1]=8
relaispins[2]=9
relaispins[3]=7
relaispins[4]=0
relaispins[5]=2
relaispins[6]=3
relaispins[7]=12
relaispins[8]=14
relaispinnames[1]="Tageslicht"
relaispinnames[2]="12V Trafo"
relaispinnames[3]="Spot Stein"
relaispinnames[4]="Spot Ecke"
relaispinnames[5]="Heizschlauch"
relaispinnames[6]="Kameraladegerät"
relaispinnames[7]="Regenmaschine"
relaispinnames[8]="Undefined"


