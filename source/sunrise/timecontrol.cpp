
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>

using namespace std;

double pi    = 3.141592653589793238463;
double todeg = 180.0/pi;
double torad = pi/180.0;
double mstep = 1.0/1440;

double riseduration = mstep*90;

struct julian {
  double jrise;
  double jset;
};

// display decimal hours in hours and minutes, but return a string instead
string hhmm(double dhr) {
  int hr,mn;
  char buffer[10];
  hr=(int) dhr;
  mn = (dhr - (double) hr)*60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hr,mn);
  return buffer;
}

// write all the values to a file with the name ddmm
void writelightsettings(double time, bool daylight, bool riseordawn, double red, double green, double blue) {
  char buffer[50],filename[50];
  ofstream filehandler;
  int seconds = time*86400;
  int hours   = seconds/3600;
  int minutes = (seconds-(hours*3600))/60;

  snprintf(filename,sizeof(filename),"%02d%02d",hours,minutes);
  snprintf(buffer,sizeof(buffer),"%i %i %1.5f %1.5f %1.5f\n",daylight,riseordawn,red,green,blue);
  
  filehandler.open(filename);
  filehandler << buffer;
  filehandler.close();
}

void stepthroughday(double dawn, double rise, double set, double dusk) {
  bool lights;
  bool riseordawn;
  double riseduration_red   = riseduration;
  double riseduration_green = riseduration*0.8;
  double riseduration_blue  = riseduration*0.6;
  double rperc = 1/riseduration_red;
  double gperc = 1/riseduration_green;
  double bperc = 1/riseduration_blue;
  double red,green,blue;

  for (double dayhour=0; dayhour<=1; dayhour+=mstep) {
    // first check if the main lights should be turned on or off
    if ((dayhour<rise) || (dayhour>set)) {
      lights=0;
    } else {
      lights=1;
    }

    // now check if we are in sunrise
    if ((dayhour>=dawn) && (dayhour<rise)) {
      riseordawn=1;
      red=(dayhour-dawn)*rperc;
      if (dayhour>=(dawn+(riseduration_red-riseduration_green))) {
        green=(dayhour-(dawn+(riseduration_red-riseduration_green)))*gperc;
      }
      if (dayhour>=(dawn+(riseduration_red-riseduration_blue))) {
        blue=(dayhour-(dawn+(riseduration_red-riseduration_blue)))*bperc;
      }
    } else if ((dayhour>set) && (dayhour<=dusk)) {
      // or are we in sunset
      red=1-((dayhour-(dusk-riseduration_red))*rperc);
      green=1-((dayhour-(dusk-riseduration_red))*gperc);
      blue=1-((dayhour-(dusk-riseduration_red))*bperc);
      riseordawn=1;
    } else {
      // or no twilight
      riseordawn=0;
      red=green=blue=0;
    }

    // turn on the led driver soon enough, so there is no dark moment
    if (dayhour+mstep>set) {
      riseordawn=1;
    }

    // failsafe if calculations took a wrong direction somewhere
    if (red>1) { red=1; }
    if (green>1) { green=1; }
    if (blue>1) { blue=1; }
    if (red<0) { red=0; }
    if (green<0) { green=0; }
    if (blue<0) { blue=0; }

    // now write the calculated values into a file
    writelightsettings(dayhour,lights,riseordawn,red,green,blue);
  }
}

struct julian calcjtimes(time_t t) {
  
  struct tm * current_time = localtime(&t);
  // longitude west of magdeburg
  double low=-11.6322;
  // latitude of magdeburg
  double lam=52.1243;
  // latitude of madagascar (if it were on northern hemishpere)
  // double lam=22.5;

  // calculate julian day number based on https://de.wikipedia.org/wiki/Julianisches_Datum
  int m=current_time->tm_mon+1;
  int y=current_time->tm_year+1900;
  if (m<=2) { m+=12; y--; } 
  int d=current_time->tm_mday;
  int a=floor((y)/100);
  double b = 2-a+floor(a/4);
  double jd = floor(365.25*(y+4716))+floor(30.6001*(m+1))+d+b-1524.5;
 
  // calculation of sunrise based on https://en.wikipedia.org/wiki/Sunrise_equation
  // current julian day
  double n = jd-2451545+0.0008;
  // mean solar noon
  double js = low/360+n;
  // mean anomaly
  double ma = fmod((357.5291+0.98560028*js),360);
  // equation of the center
  double c = 1.9148*sin(ma*torad)+0.02*sin(2*ma*torad)+0.0003*sin(3*ma*torad);
  // ecliptic longitude
  double l = fmod((ma+c+180+102.9372),360);
  // solar transit - it seems they have forgotten the 2451545.5 on the wikipedia page. or i did not understand correctly.
  double jt = 2451545.5+js+0.0053*sin(ma*torad)-0.0069*sin(2*l*torad);
  // declination of the sun
  double de = asin(sin(l*torad)*sin(23.44*torad))*todeg;
  // hour angle
  double w = acos((sin(-0.83*torad)-sin(lam*torad)*sin(de*torad))/(cos(lam*torad)*cos(de*torad)))*todeg;
  
  double jset = jt+w/360;
  double jrise = jt-w/360;

  struct julian cjt = { jrise, jset };

  return cjt;
}

int main() {
  time_t t = time(0);
  struct julian jt;
 
  // better float precision for debugging purposes
  std::cout.setf(std::ios_base::fixed, std::ios_base::floatfield);
  std::cout.precision(10);

  // debugging purposes
  /*
  struct tm * timeinfo;
  timeinfo = gmtime(&t);

  for (int x=1;x<31;x++) {
    timeinfo->tm_mday=x;
    cout << x << " ";
    jt = calcjtimes(mktime(timeinfo));
    std::cout << jt.jrise << " " << jt.jset << endl;
  }
  */

  jt = calcjtimes(t);
  
  // now we have the correct times. first skip the acutal
  // date because i only need the times. as julian day .5 is 
  // 00:00 gmt we have to subtract .5 so we get the correct
  // values for hour, minute and second.
  // they will be shifted so
  // the day of the terrarium matches the day of the owners and
  // also i want to have a nice dawn and dusk.
  // the dawn and dusk will spread evenly before and after
  // the actal sunrise

  double sunrise = (jt.jrise-.5-floor(jt.jrise-.5))+mstep*60;
  double sunset  = (jt.jset-.5-floor(jt.jset-.5))+mstep*60;
  double lightson  = sunrise+riseduration/2;
  double lightsoff = sunset-riseduration/2;
  double dawn      = sunrise-riseduration/2;
  double dusk      = sunset+riseduration/2;

  /* 
  cout << dawn << endl;
  cout << lightson << endl;
  cout << lightsoff << endl;
  cout << dusk << endl;
  cout << sunrise << endl;
  cout << sunset << endl;
  */

  stepthroughday(dawn,lightson,lightsoff,dusk);

  ofstream filehandler;
  string filename= "times";
  int sec,min,hou;
  char buffer[50];
  filehandler.open(filename.c_str());
  sec=dawn*86400;hou=sec/3600;min=(sec-(hou*3600))/60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hou,min);
  filehandler << buffer << "\t";
  sec=lightson*86400;hou=sec/3600;min=(sec-(hou*3600))/60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hou,min);
  filehandler << buffer << "\t";
  sec=lightsoff*86400;hou=sec/3600;min=(sec-(hou*3600))/60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hou,min);
  filehandler << buffer << "\t";
  sec=dusk*86400;hou=sec/3600;min=(sec-(hou*3600))/60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hou,min);
  filehandler << buffer << "\t";
  sec=sunrise*86400;hou=sec/3600;min=(sec-(hou*3600))/60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hou,min);
  filehandler << buffer << "\t";
  sec=sunset*86400;hou=sec/3600;min=(sec-(hou*3600))/60;
  snprintf(buffer,sizeof(buffer),"%02d%02d",hou,min);
  filehandler << buffer << "\t";
  filehandler << endl;
  filehandler.close();

  return 0;
}
  
