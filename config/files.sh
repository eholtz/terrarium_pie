#!/bin/bash

# this is meant to be sourced for every script that runs
# for the control of the terrarium

# be sure to be in utc mode
TZ="UTC"
export TZ

dir_tmp="/tmp/terra_control/"
dir_base=$(dirname $(readlink -f $(dirname $0)))
dir_config="$dir_base/config/"
dir_script="$dir_base/script/"
dir_bin="$dir_base/bin/"
dir_log="$dir_tmp/log/"
dir_rrd="$dir_tmp/rrd/"
dir_volatile="$dir_tmp/volatile/"
dir_html="/mnt/nfs/html/"
dir_backup="/mnt/nfs/terrarium/"

file_status="${dir_volatile}/status"

soll_temp_ecke_tag_min=23
soll_temp_ecke_tag_max=25
soll_temp_deckel_tag_max=40
soll_temp_ecke_nacht_min=20
soll_temp_ecke_nacht_max=21

epoch_current=$(date +%s)

init=0
[ ! -d $dir_tmp ] && mkdir -p $dir_tmp && init=1
[ ! -d $dir_log ] && mkdir -p $dir_log && init=1
[ ! -d $dir_rrd ] && mkdir -p $dir_rrd && init=1
[ ! -d $dir_volatile ] && mkdir -p $dir_volatile
[ ! -d $dir_html ] && mkdir -p $dir_html

rrd_gpio="$dir_rrd/gpio"
rrd_sensor="$dir_rrd/sensor"

declare -A sensors
declare -A sensoridname
declare -A sensornameid
sensors[1]=22
sensors[2]=24
sensoridname[1]="Ecke"
sensoridname[2]="Deckel"
for i in "${!sensoridname[@]}" ; do
  sensornameid[${sensoridname[$i]}]=$i
done

declare -A relaispins
declare -A relaispinname
declare -A relaisnamepin
declare -A switchrelais
relaispins[1]=8
relaispins[2]=9
relaispins[3]=7
relaispins[4]=0
relaispins[5]=2
relaispins[6]=3
relaispins[7]=12
relaispins[8]=14
relaispinname[1]="Tageslicht"
relaispinname[2]="12V Trafo"
relaispinname[3]="Spot Stein"
relaispinname[4]="Spot Ecke"
relaispinname[5]="Heizschlauch"
relaispinname[6]="Kameraladegerät"
relaispinname[7]="Regenmaschine"
relaispinname[8]="Undefined"
for i in "${!relaispinname[@]}" ; do
  relaisnamepin[${relaispinname[$i]}]=$i
done

if [ $init -eq 1 ] ; then
  echo "$(date) re-init " > $dir_log/_init
  source $dir_script/init.sh
fi

