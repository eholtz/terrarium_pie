#!/bin/bash

# this runs to read and update all rrd data

source "$(readlink -f $(dirname $0)/../config/files.sh)"
source $dir_script/read_sensors.sh


