// Compile with: gcc -lm -o testSHT1x ./../bcm2835-1.8/src/bcm2835.c ./RPi_SHT1x.c testSHT1x.c

/*
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

SHT pins:
1. GND  - Connected to GPIO Port P1-06 (Ground)
2. DATA - Connected via a 10k pullup resistor to GPIO Port P1-01 (3V3 Power)
2. DATA - Connected to GPIO Port P1-18 (GPIO 24)
3. SCK  - Connected to GPIO Port P1-16 (GPIO 23)
4. VDD  - Connected to GPIO Port P1-01 (3V3 Power)

Note:
GPIO Pins can be changed in the Defines of RPi_SHT1x.h
*/

#include <bcm2835.h>
#include <stdio.h>
#include "RPi_SHT1x_##MYPIN##.h"
#include <math.h>

#define NUMMEASURES 11

float calcsd(float data[],float min, float max);
float calcmean(float data[], float min, float max);

float gettemp(void)
{
	value humi_val, temp_val;
	delay(23);
	SHT1x_InitPins();
	SHT1x_Reset();
	SHT1x_Measure_Start(SHT1xMeaT);
	SHT1x_Get_Measure_Value((unsigned short int *)&temp_val.i);
	temp_val.f = (float)temp_val.i;
	humi_val.f = 0.0;
	SHT1x_Calc(&humi_val.f, &temp_val.f);
	return temp_val.f;
}

float gethumi(void)
{
	value humi_val, temp_val;
	delay(23);
	SHT1x_InitPins();
	SHT1x_Reset();
	SHT1x_Measure_Start(SHT1xMeaRh);
	SHT1x_Get_Measure_Value((unsigned short int *)&humi_val.i);
	humi_val.f = (float)humi_val.i;
	temp_val.f = 0.0;
	SHT1x_Calc(&humi_val.f, &temp_val.f);
	return humi_val.f;
}

int th(void)
{
	int x = 0, y = 0;
	int maxtries = 10;

	float temp[NUMMEASURES];
	float humi[NUMMEASURES];

	float sumsd = 0.0;

		for (y = 0; y < NUMMEASURES; y++)
		{
			temp[y] = gettemp();
			humi[y] = gethumi();
		}
			sumsd = calcsd(temp,15,50) + calcsd(humi,40,100);
		if (sumsd < 1)
	{
		printf("%0.2f\n%0.2f\n", calcmean(temp,15,50), calcmean(humi,40,100));
		return 0;
	}
	else
	{
		printf("NaN\nNaN\n");
		return 1;
	}
}

float calcmean(float data[], float min, float max)
{
	float sum = 0.0, mean = 0.0;
	int i = 0;
	int c = 0;
	for (i = 0; i < NUMMEASURES; i++)
	{
		if ((data[i]>min) && (data[i]<max)) {
			sum += data[i];
			c++;
		}
	}
	return sum / c;
}

float calcsd(float data[], float min, float max)
{
	float sum = 0.0, mean = 0.0, sd = 0.0;
	int i = 0;
	int c = 0;
	mean = calcmean(data,min,max);
	//	printf("sum %f\n",sum);
	//	printf("mean %f\n",mean);
	for (i = 0; i < NUMMEASURES; i++)
	{
		if ((data[i]<max) && (data[i]>min)) {
			sd += pow(data[i] - mean, 2);
			c++;
		}
	}
	return sqrt(sd / c);
}

int main()
{
	//Initialise the Raspberry Pi GPIO
	if (!bcm2835_init()) {
		return 1;
} else {
	return th();
}
}
