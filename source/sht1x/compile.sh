#!/bin/bash
for i in $(seq 1 3); do gcc -lm -o sensor$i ../bcm2835-1.50/src/bcm2835.c ./RPi_SHT1x_s$i.c ./testSHT1x.c ; done
