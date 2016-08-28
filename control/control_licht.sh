#!/bin/bash

source lichtdefs.sh

ctf="/tmpfs/$(date +%H%m)"
read daylight ledstripe red green blue < $ctf

[ $daylight -eq 1 ] && turnon 11 $onf
[ $daylight -eq 0 ] && turnoff 11 $off
[ $ledstripe -eq 1 ] && turnon 26 $ledonf
[ $ledstripe -eq 0 ] && turnoff 26 $ledoff
echo "7=${red}" > /dev/pi-blaster
echo "8=${green}" > /dev/pi-blaster
echo "25=${blue}" > /dev/pi-blaster


