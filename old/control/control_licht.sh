#!/bin/bash

ctf="${definitionsdir}/$(date +%H%M)"
read daylight ledstripe red green blue < $ctf

[ $daylight -eq 1 ] && gpio write $pin_tageslicht 1
[ $daylight -eq 0 ] && gpio write $pin_tageslicht 0
[ $ledstripe -eq 1 ] && gpio write $pin_trafo 1
[ $ledstripe -eq 0 ] && gpio write $pin_trafo 0

echo "14=${red}" > /dev/pi-blaster
echo "15=${green}" > /dev/pi-blaster
echo "18=${blue}" > /dev/pi-blaster


