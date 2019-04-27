/*
Raspberry Pi SHT1x communication lib with ability
to specify the pins *not* in the header file.
by Eike Holtz / https://github.com/eholtz

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
*/

#ifndef RPI_SHT1x_H_
#define RPI_SHT1x_H_

// Includes
#include <bcm2835.h>
#include <math.h>
#include <stdio.h>
#include <unistd.h>


// Defines
#define TRUE 1
#define FALSE 0
#define SHT1x_DELAY delayMicroseconds(2)

// Define the Raspberry Pi GPIO Pin for the SHT1x clock
#define RPI_GPIO_SHT1x_SCK RPI_GPIO_P1_16

/* Macros to toggle port state of SCK line. */
#define SHT1x_SCK_LO bcm2835_gpio_write(RPI_GPIO_SHT1x_SCK, LOW)
#define SHT1x_SCK_HI bcm2835_gpio_write(RPI_GPIO_SHT1x_SCK, HIGH)

/* Definitions of all known SHT1x commands */
#define SHT1x_MEAS_T 0x03   // Start measuring of temperature.
#define SHT1x_MEAS_RH 0x05  // Start measuring of humidity.
#define SHT1x_STATUS_R 0x07 // Read status register.
#define SHT1x_STATUS_W 0x06 // Write status register.
#define SHT1x_RESET 0x1E    // Perform a sensor soft reset.

/* Enum to select between temperature and humidity measuring */
typedef enum _SHT1xMeasureType {
  SHT1xMeaT = SHT1x_MEAS_T,  // Temperature
  SHT1xMeaRh = SHT1x_MEAS_RH // Humidity
} SHT1xMeasureType;

typedef union {
  unsigned short int i;
  float f;
} value;

/* Public Functions ----------------------------------------------------------- */
void SHT1x_Transmission_Start(unsigned char datapin);
unsigned char SHT1x_Readbyte(unsigned char sendAck, unsigned char datapin);
unsigned char SHT1x_Sendbyte(unsigned char value, unsigned char datapin);
void SHT1x_InitPins(unsigned char datapin);
unsigned char SHT1x_Measure_Start(SHT1xMeasureType type, unsigned char datapin);
unsigned char SHT1x_Get_Measure_Value(unsigned short int *value, unsigned char datapin);
void SHT1x_Reset(unsigned char datapin);
unsigned char SHT1x_Mirrorbyte(unsigned char value);
void SHT1x_Xrc_check(unsigned char value);
void SHT1x_Calc(float *p_humidity, float *p_temperature);
void SHT1x_CalcDewpoint(float fRH, float fTemp, float *fDP);
#endif
