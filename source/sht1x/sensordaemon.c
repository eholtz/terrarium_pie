/*
Daemon to read one or more SHT1x sensors
by Eike Holtz / https://github.com/eholtz
Compile with: gcc -lm -I../libs/bcm2835-1.55/src/ -o sensordaemon ../libs/bcm2835-1.55/src/bcm2835.c ./RPi_SHT1x.c sensordaemon.c

Raspberry Pi SHT1x communication library.
By:      John Burns (www.john.geek.nz)
Date:    01 November 2012
License: CC BY-SA v3.0 - http://creativecommons.org/licenses/by-sa/3.0/

This is a derivative work based on
Name: Nice Guy SHT11 library
By: Daesung Kim
Date: 04/04/2011
Source: http://www.theniceguy.net/2722
License: Unknown - Attempts have been made to contact the author

Dependencies:
BCM2835 Raspberry Pi GPIO Library - http://www.open.com.au/mikem/bcm2835/

Sensor:
Sensirion SHT11 Temperature and Humidity Sensor interfaced to Raspberry Pi GPIO port

*/

#include "RPi_SHT1x.h"
#include <bcm2835.h>
#include <math.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>

// define number of measurements
// we will output the median
#define NUMMEASURES 7

// number of sensors
#define SENSORCOUNT 1

// pins to control
// wiring pi pins
static unsigned short sensor_pins[SENSORCOUNT] = {
    RPI_V2_GPIO_P1_22
//    RPI_V2_GPIO_P1_24,
//    RPI_V2_GPIO_P1_18
};

float calcsd(float data[], float min, float max);
float calcmean(float data[], float min, float max);

float gettemp(unsigned char pin) {
  value humi_val, temp_val;
  delay(23);
  SHT1x_InitPins(pin);
  SHT1x_Reset(pin);
  SHT1x_Measure_Start(SHT1xMeaT, pin);
  SHT1x_Get_Measure_Value((unsigned short int *)&temp_val.i, pin);
  temp_val.f = (float)temp_val.i;
  humi_val.f = 0.0;
  SHT1x_Calc(&humi_val.f, &temp_val.f);
  return temp_val.f;
}

float gethumi(unsigned char pin) {
  value humi_val, temp_val;
  delay(23);
  SHT1x_InitPins(pin);
  SHT1x_Reset(pin);
  SHT1x_Measure_Start(SHT1xMeaRh, pin);
  SHT1x_Get_Measure_Value((unsigned short int *)&humi_val.i, pin);
  humi_val.f = (float)humi_val.i;
  temp_val.f = 0.0;
  SHT1x_Calc(&humi_val.f, &temp_val.f);
  return humi_val.f;
}

void th(unsigned char pin, char *values, int bufsize) {

  float temp[NUMMEASURES];
  float humi[NUMMEASURES];
  char humis[23];
  char temps[23];

  for (int y = 0; y < NUMMEASURES; y++) {
    temp[y] = gettemp(pin);
    humi[y] = gethumi(pin);
  }
  // we are calculating first the standard deviation of our
  // measurements that are in a accetable range. if so
  // the mean will be calculated (all values not in our
  // acceptable range will be discarded).
  // range for temp: 14 to 50 °C
  // range for humi: 40 to 100 %

  if (calcsd(temp, 15, 50) < 1) {
    snprintf(temps, sizeof(temps), "%0.2f", calcmean(temp, 15, 50));
  } else {
    snprintf(temps, sizeof(temps), "NaN");
  }
  if (calcsd(humi, 40, 100) < 1) {
    snprintf(humis, sizeof(humis), "%0.2f", calcmean(humi, 40, 100));
  } else {
    snprintf(humis, sizeof(humis), "%0.2f");
  }
  snprintf(values, bufsize, "%d %s %s", pin, temps, humis);
  values[bufsize - 1] = '\0';
}

float calcmean(float data[], float min, float max) {
  float sum = 0.0, mean = 0.0;
  int i = 0;
  int c = 0;
  for (i = 0; i < NUMMEASURES; i++) {
    if ((data[i] > min) && (data[i] < max)) {
      sum += data[i];
      c++;
    }
  }
  return sum / c;
}

float calcsd(float data[], float min, float max) {
  float sum = 0.0, mean = 0.0, sd = 0.0;
  int i = 0;
  int c = 0;
  mean = calcmean(data, min, max);
  //	printf("sum %f\n",sum);
  //	printf("mean %f\n",mean);
  for (i = 0; i < NUMMEASURES; i++) {
    if ((data[i] < max) && (data[i] > min)) {
      sd += pow(data[i] - mean, 2);
      c++;
    }
  }
  return sqrt(sd / c);
}

int main() {
  unsigned short failcounter = 0;
  time_t now = time(0);
  char buffer[128];
  // mkdir did not work for some strange reason, so I'm lazy
  snprintf(buffer, sizeof(buffer), "mkdir -p /dev/shm/sensors/");
  system(buffer);
  printf("executed %s\n",buffer);

  while (1 == 1) {
    // Initialise the Raspberry Pi GPIO
    if (!bcm2835_init()) {
      printf("ERROR: Could not init bcm2835!\n");
      failcounter++;
    } else {
      now = time(0);
      sprintf(buffer, "/dev/shm/sensors/%d", now);
      FILE *fp = fopen(buffer, "w");
      if (fp == NULL) {
        printf("ERROR: Could not open %s\n", buffer);
      } else {
        sprintf(buffer,"/dev/shm/sensors_last");
        FILE *slfp = fopen(buffer, "w");
        if (slfp == NULL) {
          printf("ERROR: Could not open %s\n", buffer);
        } else {
//          fprintf(slfp,"pin temperature humidity\n");
          for (int sensornum = 0; sensornum < SENSORCOUNT; sensornum++) {
            // printf("reading sensor number %d\n", sensornum);
            th(sensor_pins[sensornum], buffer, sizeof(buffer));
            fprintf(fp,"%s\n",buffer);
            fprintf(slfp,"%s\n",buffer);
	    printf("%s\n",buffer);
          }
          fclose(slfp);
        }
        fclose(fp);
      }
      failcounter = 0;
    }
    // if we did not get any value within the last
    // two minutes we'll exit
    if (failcounter > 12) {
      return 1;
    }
    // sleep for 10 seconds
    usleep(10000000);
  }
}
