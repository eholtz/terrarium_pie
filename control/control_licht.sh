#!/bin/bash

#source lichtdefs.sh
source functions.sh

[ $sun_on ] && turnon 20 /tmpfs/sun.on
[ $sun_on ] || turnoff 20 /tmpfs/sun.off
#[ $light_on ] && turnon 21 /tmpfs/t5.on
#[ $light_on ] || turnoff 21 /tmpfs/t5.off

ctf="/tmpfs/$(date +%H%M)"
read daylight ledstripe red green blue < $ctf

[ $daylight -eq 1 ] && turnon 21 /tmpfs/t5.on
[ $daylight -eq 0 ] && turnoff 21 /tmpfs/t5.off
[ $ledstripe -eq 1 ] && turnon 16 /tmpfs/led.on
[ $ledstripe -eq 0 ] && turnoff 16 /tmpfs/led.off
echo "14=${red}" > /dev/pi-blaster
echo "15=${green}" > /dev/pi-blaster
echo "18=${blue}" > /dev/pi-blaster

