// Some part of the code is from 
// jjlammi@netti.fi
// http://www.sci.fi/~benefon/rscalc_cpp.html

#include <stdio.h>
#include <math.h>
#include <time.h>
#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>

using namespace std;

double pi   = 3.141592653589793238463;
double tpi  = 2 * pi;
double degs = 180.0/pi;
double rads = pi/180.0;

double L,g,daylen;
double SunDia = 0.53;  // Sunradius degrees

double AirRefr = 34.0/60.0; // athmospheric refraction degrees //

// Get the days to J2000
// h is UT in decimal hours
// FNday only works between 1901 to 2099 - see Meeus chapter 7

double FNday (int y, int m, int d, float h) {
  long int luku = - 7 * (y + (m + 9)/12)/4 + 275*m/9 + d;

  // Typecasting needed for TClite on PC DOS at least, to avoid product overflow
  luku+= (long int)y*367;

  return (double)luku - 730531.5 + h/24.0;
};

// the function below returns an angle in the range
// 0 to 2*pi

double FNrange (double x) {
  double b = x / tpi;
  double a = tpi * (b - (long)(b));
  if (a < 0) a = tpi + a;
  return a;
};

// Calculating the hourangle
double f0(double lat, double declin) {

  double fo,dfo;
  // Correction: different sign at S HS
  dfo = rads*(0.5*SunDia + AirRefr); if (lat < 0.0) dfo = -dfo;
  fo = tan(declin + dfo) * tan(lat*rads);

  if (fo > 0.99999) fo=1.0; // to avoid overflow //
  fo = asin(fo) + pi/2.0;
  return fo;
};

// Calculating the hourangle for twilight times
//
double f1(double lat, double declin) {

  double fi,df1;
  // Correction: different sign at S HS
  df1 = rads * 6.0; if (lat < 0.0) df1 = -df1;
  fi = tan(declin + df1) * tan(lat*rads);

  if (fi > 0.99999) fi=1.0; // to avoid overflow //
  fi = asin(fi) + pi/2.0;
  return fi;
};

// Find the ecliptic longitude of the Sun
double FNsun (double d) {

  // mean longitude of the Sun
  L = FNrange(280.461 * rads + .9856474 * rads * d);

  // mean anomaly of the Sun
  g = FNrange(357.528 * rads + .9856003 * rads * d);

  // Ecliptic longitude of the Sun
  return FNrange(L + 1.915 * rads * sin(g) + .02 * rads * sin(2 * g));
};

// Display decimal hours in hours and minutes
void showhrmn(double dhr) {
  int hr,mn;
  hr=(int) dhr;
  mn = (dhr - (double) hr)*60;
  printf("%02d:%02d",hr,mn);
};

// Display decimal hours in hours and minutes, but return a string instead
string hhmm(double dhr) {
  int hr,mn;
  char buffer[10];
  hr=(int) dhr;
  mn = (dhr - (double) hr)*60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hr,mn);
  return buffer;
}

// Write the given values into a file. This is rather hacky but does the job.
void writelightsettings(double time,double lights, double riseordawn, double red,double green, double blue) {
  char buffer[50];
  ofstream filehandler;
  string filename;
  filename = hhmm(time);
  snprintf(buffer,sizeof(buffer),"%1.0f %1.0f %1.5f %1.5f %1.5f\n",lights,riseordawn,red,green,blue);
  filehandler.open(filename.c_str());
  filehandler << buffer;
  filehandler.close();
}

void writerisedawntimes(double dawnstart, double daystart, double daystop, double duskstop, double adstart, double adstop) {
  ofstream filehandler;
  string filename;
  filename = "times";
  filehandler.open(filename.c_str());
  filehandler << hhmm(dawnstart) << "\n";
  filehandler << hhmm(daystart) << "\n";
  filehandler << hhmm(daystop) << "\n";
  filehandler << hhmm(duskstop) << "\n";
  filehandler << hhmm(adstart) << "\n";
  filehandler << hhmm(adstop) << "\n";
  filehandler.close();
}


int main(void) {
  double y,m,day,h,latit,longit;

  time_t sekunnit;
  struct tm *p;

  // get the date and time from the user
  // read system date and extract the year

  /** First get current time **/
  time(&sekunnit);

  /** Next get localtime **/

  p=localtime(&sekunnit);
  // this is Y2K compliant algorithm
  y = 1900 + p->tm_year;

  m = p->tm_mon + 1;
  day = p->tm_mday;
  h = 12;

  // magdeburg
  // latit = 52.8;
  
  // madagascar
  latit = 20.0;
  // we leave longitude as it is, that will only affect time zone
  longit= 11.37;
  // we will go for utc
  double tzone = 0;

  double d = FNday(y, m, day, h);

  // Use FNsun to find the ecliptic longitude of the
  // Sun

  double lambda = FNsun(d);

  // Obliquity of the ecliptic

  double obliq = 23.439 * rads - .0000004 * rads * d;

  // Find the RA and DEC of the Sun

  double alpha = atan2(cos(obliq) * sin(lambda), cos(lambda));
  double delta = asin(sin(obliq) * sin(lambda));

  // Find the Equation of Time in minutes
  // Correction suggested by David Smith

  double LL = L - alpha;
  if (L < pi) LL += tpi;
  double equation = 1440.0 * (1.0 - LL / tpi);


  double ha = f0(latit,delta);

  double hb = f1(latit,delta);
  double twx = hb - ha;   // length of twilight in radians
  twx = 12.0*twx/pi;      // length of twilight in degrees

  // Conversion of angle to hours and minutes //
  daylen = degs * ha / 7.5;
  if (daylen<0.0001) {daylen = 0.0;}
  // arctic winter   //

  double riset = 12.0 - 12.0 * ha/pi + tzone - longit/15.0 + equation/60.0;
  double settm = 12.0 + 12.0 * ha/pi + tzone - longit/15.0 + equation/60.0;

  // shift by one hour - that's to have the day of the terrarium more
  // aligned to the day of the owners
  riset+=1;
  settm+=1;

  double twam = riset - twx;      // morning twilight begin
  double twpm = settm + twx;      // evening twilight end

  if (riset > 24.0) riset-= 24.0;
  if (settm > 24.0) settm-= 24.0;


  // debug output
  /*
  printf("\n Sunrise and set\n");
  printf("yyyy-mm-dd    : %04.0f-%02.0f-%02.0f\n",y,m,day);
  printf("Daylength     : ");
  showhrmn(daylen);
  printf(" hours\n");
  printf("Begin twilight: ");
  showhrmn(twam);
  printf("\nSunrise       : ");
  showhrmn(riset);
  printf("\nSunset        : ");
  showhrmn(settm);
  printf("\nEnd twiglight : ");
  showhrmn(twpm);
  printf("\n");
  */

  // most of those values could be int, though...
  int colorsteps=1;
  double minutestep=1.0/60.0*1;
  double dayhour=0;
  double red=0,green=0,blue=0;
  double lights=0,riseordawn=0;
  double riseduration_red=1.5;
  double riseduration_green=riseduration_red*0.8;
  double riseduration_blue=riseduration_red*0.6;
  double rperc=1/riseduration_red*colorsteps;
  double gperc=1/riseduration_green*colorsteps;
  double bperc=1/riseduration_blue*colorsteps;
  double perc=0;

  writerisedawntimes(twam,twam+riseduration_red,twpm-riseduration_red,twpm,riset,settm);

  for (dayhour=0; dayhour<24; dayhour+=minutestep) {
    // first check if the main lights should be turned on or off
    if ((dayhour<(twam+riseduration_red)) || (dayhour>(twpm-riseduration_red))) {
      lights=0;
    } else {
      lights=1;
    }

    // now check if we are in sunrise
    if ((dayhour>=twam) && (dayhour<(twam+riseduration_red))) {
        riseordawn=1;
        red=(dayhour-twam)*rperc;
        if (dayhour>=(twam+(riseduration_red-riseduration_green))) {
          green=(dayhour-(twam+(riseduration_red-riseduration_green)))*gperc;
        }
        if (dayhour>=(twam+(riseduration_red-riseduration_blue))) {
          blue=(dayhour-(twam+(riseduration_red-riseduration_blue)))*bperc;
        }
    } else if ((dayhour>=(twpm-riseduration_red)) && (dayhour<=twpm)) {
      // or are we in sunset
      red=colorsteps-((dayhour-(twpm-riseduration_red))*rperc);
      green=colorsteps-((dayhour-(twpm-riseduration_red))*gperc);
      blue=colorsteps-((dayhour-(twpm-riseduration_red))*bperc);
      riseordawn=1;
    } else {
      // or no twilight
      riseordawn=0;
      red=green=blue=0;
    }

    // failsafe if calculations took a wrong direction somewhere
    if (red>colorsteps) { red=colorsteps; }
    if (green>colorsteps) { green=colorsteps; }
    if (blue>colorsteps) { blue=colorsteps; }
    if (red<0) { red=0; }
    if (green<0) { green=0; }
    if (blue<0) { blue=0; }
    
    // now write the calculated values into a file
    writelightsettings(dayhour,lights,riseordawn,red,green,blue);    
  }
  return 0;
}

