#!/bin/bash

[ -z "$1" ] && echo "first and only param should be the gpio pin to read" && exit 0

cp RPi_SHT1x.c RPi_SHT1x_$1.c
cp RPi_SHT1x.h RPi_SHT1x_$1.h
cp read_sensor.c read_sensor_$1.c
sed -i "s/##MYPIN##/$1/g" RPi_SHT1x_$1.c
sed -i "s/##MYPIN##/$1/g" RPi_SHT1x_$1.h
sed -i "S/##MYPIN##/$1/g" read_sensor_$1.c

bcmsrc=$(find ../ -iname bcm2835.c | head -n 1)
gcc -lm -o read_sensor_$i $bcmsrc ./RPi_SHT1x_s$i.c read_sensor_$1.c

rm RPi_SHT1x_$1.c
rm RPi_SHT1x_$1.h
rm read_sensor_$1.c

