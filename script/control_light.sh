#!/bin/bash

file_current_lightvalues="${dir_volatile}/$(date +%H%M)"
read daylight ledstripe red green blue < $file_current_lightvalues

[ $daylight -eq 1 ] && gpio write ${relaisnamepin["Tageslicht"]} 1
[ $daylight -eq 0 ] && gpio write ${relaisnamepin["Tageslicht"]} 0
[ $ledstripe -eq 1 ] && gpio write ${relaisnamepin["12V Trafo"]} 1
[ $ledstripe -eq 0 ] && gpio write ${relaisnamepin["12V Trafo"]} 0

echo "14=${red}" > /dev/pi-blaster
echo "15=${green}" > /dev/pi-blaster
echo "18=${blue}" > /dev/pi-blaster


