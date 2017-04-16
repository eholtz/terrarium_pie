#!/bin/bash

file_current_lightvalues="${dir_volatile}/$(date +%H%M)"
read daylight ledstripe red green blue < $file_current_lightvalues

echo "Read $daylight $ledstripe $red $green $blue from $file_current_lightvalues"

[ $daylight -eq 1 ] && switchrelais[${relaisnamepin["Tageslicht"]}]=1
[ $daylight -eq 0 ] && switchrelais[${relaisnamepin["Tageslicht"]}]=0
[ $ledstripe -eq 1 ] && switchrelais[${relaisnamepin["12V Trafo"]}]=1
[ $ledstripe -eq 0 ] && switchrelais[${relaisnamepin["12V Trafo"]}]=0

echo "14=${red}" > /dev/pi-blaster
echo "15=${green}" > /dev/pi-blaster
echo "18=${blue}" > /dev/pi-blaster


