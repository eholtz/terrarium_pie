/*
Raspberry Pi SHT1x communication lib with ability
to specify the pins *not* in the header file.
by Eike Holtz / https://github.com/eholtz

Mostly based on:
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

#include "RPi_SHT1x.h"

/* Global variables of the SHT1x sensor */
unsigned char SHT1x_crc;
unsigned char SHT1x_status_reg = 0;

void SHT1x_DATA_LO(unsigned char datapin) {
  bcm2835_gpio_write(datapin, LOW);
  bcm2835_gpio_fsel(datapin, BCM2835_GPIO_FSEL_OUTP);
}

void SHT1x_DATA_HI(unsigned char datapin) { bcm2835_gpio_fsel(datapin, BCM2835_GPIO_FSEL_INPT); }

uint8_t SHT1x_GET_BIT(unsigned char datapin) { return bcm2835_gpio_lev(datapin); }

void SHT1x_Crc_Check(unsigned char value) {
  unsigned char i;

  for (i = 8; i; i--) {
    if ((SHT1x_crc ^ value) & 0x80) {
      SHT1x_crc <<= 1;
      SHT1x_crc ^= 0x31;
    } else {
      SHT1x_crc <<= 1;
    }
    value <<= 1;
  }
}

void SHT1x_InitPins(unsigned char datapin) {
  // SCK line as output but set to low first
  bcm2835_gpio_write(RPI_GPIO_SHT1x_SCK, LOW);
  bcm2835_gpio_fsel(RPI_GPIO_SHT1x_SCK, BCM2835_GPIO_FSEL_OUTP);
  bcm2835_gpio_write(RPI_GPIO_SHT1x_SCK, LOW);

  // DATA to input. External pull up.
  // Set PORT to 0 => pull data line low by setting port as output
  bcm2835_gpio_set_pud(datapin, BCM2835_GPIO_PUD_OFF);
  bcm2835_gpio_write(datapin, LOW);
  bcm2835_gpio_fsel(datapin, BCM2835_GPIO_FSEL_OUTP);
  bcm2835_gpio_set_pud(datapin, BCM2835_GPIO_PUD_OFF);
  bcm2835_gpio_write(datapin, LOW);
}

void SHT1x_Reset(unsigned char datapin) {
  // Chapter 3.4
  unsigned char i;
  SHT1x_DATA_HI(datapin);
  SHT1x_DELAY;
  for (i = 9; i; i--) {
    SHT1x_SCK_HI;
    SHT1x_DELAY;
    SHT1x_SCK_LO;
    SHT1x_DELAY;
  }
  SHT1x_Transmission_Start(datapin);
  SHT1x_Sendbyte(SHT1x_RESET, datapin); // Soft reset
}

void SHT1x_Transmission_Start(unsigned char datapin) {
  // Chapter 3.2
  SHT1x_SCK_HI;
  SHT1x_DELAY;
  SHT1x_DATA_LO(datapin);
  SHT1x_DELAY;
  SHT1x_SCK_LO;
  SHT1x_DELAY;
  SHT1x_SCK_HI;
  SHT1x_DELAY;
  SHT1x_DATA_HI(datapin);
  SHT1x_DELAY;
  SHT1x_SCK_LO;
  SHT1x_DELAY;

  // Reset crc calculation. Start value is the content of the status register.
  SHT1x_crc = SHT1x_Mirrorbyte(SHT1x_status_reg & 0x0F);
}

unsigned char SHT1x_Mirrorbyte(unsigned char value) {
  unsigned char ret = 0, i;

  for (i = 0x80; i; i >>= 1) {
    if (value & 0x01)
      ret |= i;

    value >>= 1;
  }

  return ret;
}

unsigned char SHT1x_Readbyte(unsigned char send_ack, unsigned char datapin) {
  unsigned char mask;
  unsigned char value = 0;

  // SCK is low here !
  for (mask = 0x80; mask; mask >>= 1) {
    SHT1x_SCK_HI;
    SHT1x_DELAY;                     // SCK hi
    if (SHT1x_GET_BIT(datapin) != 0) // and read data
      value |= mask;

    SHT1x_SCK_LO;
    SHT1x_DELAY; // SCK lo => sensor puts new data
  }

  /* send ACK if required */
  if (send_ack) {
    SHT1x_DATA_LO(datapin);
    SHT1x_DELAY; // Get DATA line
  }

  SHT1x_SCK_HI;
  SHT1x_DELAY; // give a clock pulse
  SHT1x_SCK_LO;
  SHT1x_DELAY;

  if (send_ack) { // Release DATA line
    SHT1x_DATA_HI(datapin);
    SHT1x_DELAY;
  }

  return value;
}

unsigned char SHT1x_Sendbyte(unsigned char value, unsigned char datapin) {
  unsigned char mask;
  unsigned char ack;

  for (mask = 0x80; mask; mask >>= 1) {
    SHT1x_SCK_LO;
    SHT1x_DELAY;

    if (value & mask) {
      SHT1x_DATA_HI(datapin);
      SHT1x_DELAY;
    } else {
      SHT1x_DATA_LO(datapin);
      SHT1x_DELAY;
    }

    SHT1x_SCK_HI;
    SHT1x_DELAY; // SCK hi => sensor reads data
  }
  SHT1x_SCK_LO;
  SHT1x_DELAY;

  // Release DATA line
  SHT1x_DATA_HI(datapin);
  SHT1x_DELAY;
  SHT1x_SCK_HI;
  SHT1x_DELAY;

  ack = 0;

  if (!SHT1x_GET_BIT(datapin))
    ack = 1;

  SHT1x_SCK_LO;
  SHT1x_DELAY;

  SHT1x_Crc_Check(value); // crc calculation

  return ack;
}

unsigned char SHT1x_Measure_Start(SHT1xMeasureType type, unsigned char datapin) {
  // send a transmission start and reset crc calculation
  SHT1x_Transmission_Start(datapin);
  // send command. Crc gets updated!
  return SHT1x_Sendbyte((unsigned char)type, datapin);
}

unsigned char SHT1x_Get_Measure_Value(unsigned short int *value, unsigned char datapin) {
  unsigned char *chPtr = (unsigned char *)value;
  unsigned char checksum;
  unsigned char delay_count = 62; /* delay is 62 * 5ms */

  /* Wait for measurement to complete (DATA pin gets LOW) */
  /* Raise an error after we waited 250ms without success (210ms + 15%) */
  while (SHT1x_GET_BIT(datapin)) {
    delayMicroseconds(5000); // $$$$$$$$$$$$$$$$$$ 1 ms not working $$$$$$$$$$$$$$$$$$$$$$$$

    delay_count--;
    if (delay_count == 0)
      return FALSE;
  }

  *(chPtr + 1) = SHT1x_Readbyte(TRUE, datapin); // read hi byte
  SHT1x_Crc_Check(*(chPtr + 1));                // crc calculation
  *chPtr = SHT1x_Readbyte(TRUE, datapin);       // read lo byte
  SHT1x_Crc_Check(*chPtr);                      // crc calculation

  checksum = SHT1x_Readbyte(FALSE, datapin); // crc calculation
  // compare it.
  return SHT1x_Mirrorbyte(checksum) == SHT1x_crc ? TRUE : FALSE;
}

//----------------------------------------------------------------------------------------
void SHT1x_Calc(float *p_humidity, float *p_temperature)
//----------------------------------------------------------------------------------------
{
  const float C1 = -2.0468;       // for 12 Bit
  const float C2 = +0.0367;       // for 12 Bit
  const float C3 = -0.0000015955; // for 12 Bit
  const float T1 = +0.01;         // for 12 Bit
  const float T2 = +0.00008;      // for 12 Bit

  const float D1 = -39.66; // For 3.3 Volt power supply, Centigrade
  const float D2 = 0.01;   // For 14 Bit temperature, Centigrade

  float rh = *p_humidity;   // rh:      Humidity [Ticks] 12 Bit
  float t = *p_temperature; // t:       Temperature [Ticks] 14 Bit
  float rh_lin;             // rh_lin:  Humidity linear
  float rh_true;            // rh_true: Temperature compensated humidity
  float t_C;                // t_C   :  Temperature [C]

  t_C = D1 + (D2 * t);                              // calc. temperature from ticks to [C]
  rh_lin = C1 + (C2 * rh) + (C3 * rh * rh);         // calc. humidity from ticks to [%RH]
  rh_true = (t_C - 25) * (T1 + (T2 * rh)) + rh_lin; // calc. temperature compensated humidity [%RH]
  if (rh_true > 100)
    rh_true = 100; // cut if the value is outside of
  if (rh_true < 0.1)
    rh_true = 0.1;       // the physical possible range
  *p_temperature = t_C;  // return temperature [C]
  *p_humidity = rh_true; // return humidity[%RH]
}

//----------------------------------------------------------------------------------------
void SHT1x_CalcDewpoint(float fRH, float fTemp, float *fDP)
//----------------------------------------------------------------------------------------
// Calculates Dewpoint based on Page 9 (v5, Dec 2011) of SHT1x Datasheet
{
  // Set some constants for the temperature range
  float Tn = 243.12;
  float m = 17.62;
  if (fTemp < 0) {
    Tn = 272.62;
    m = 22.46;
  }
  float lnRH = log(fRH / 100);
  float mTTnT = (m * fTemp) / (Tn + fTemp);

  *fDP = Tn * ((lnRH + mTTnT) / (m - lnRH - mTTnT));
}
