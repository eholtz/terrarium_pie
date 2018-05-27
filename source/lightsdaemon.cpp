#include <fstream>
#include <iostream>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <time.h>
#include <unistd.h>

using namespace std;

double pi = 3.141592653589793238463;
double todeg = 180.0 / pi;
double torad = pi / 180.0;
double hstep = 1.0 / 24;
double mstep = 1.0 / 1440;
double sstep = 1.0 / 86400;

double riseduration = sstep * 5400;

struct julian {
  double jrise;
  double jset;
};

// display fraction of a day in hours and minutes, but return a string
string j2h(double jd) {
  int hr, mn;
  char buffer[10];
  hr = (int)(jd * 24);
  mn = (int)(((jd * 24) - (double(hr))) * 60);
  snprintf(buffer, sizeof(buffer), "%02d:%02d", hr, mn);
  return buffer;
}

void setlights(double dayhour, double dawn, double rise, double set, double dusk) {
  bool lights;
  bool riseordawn;
  double riseduration_red = riseduration;
  double riseduration_green = riseduration * 0.8;
  double riseduration_blue = riseduration * 0.6;
  double rperc = 1 / riseduration_red;
  double gperc = 1 / riseduration_green;
  double bperc = 1 / riseduration_blue;
  double red = 0, green = 0, blue = 0;
  ofstream filehandler;
  string filename;

  // first check if the main lights should be turned on or off
  if ((dayhour < rise) || (dayhour > set)) {
    lights = 0;
  } else {
    lights = 1;
  }

  // now check if we are in sunrise
  if ((dayhour >= dawn) && (dayhour <= (rise + mstep))) {
    riseordawn = 1;
    red = (dayhour - dawn) * rperc;
    if (dayhour >= (dawn + (riseduration_red - riseduration_green))) {
      green = (dayhour - (dawn + (riseduration_red - riseduration_green))) * gperc;
    }
    if (dayhour >= (dawn + (riseduration_red - riseduration_blue))) {
      blue = (dayhour - (dawn + (riseduration_red - riseduration_blue))) * bperc;
    }
  } else if ((dayhour >= (set - mstep)) && (dayhour <= dusk)) {
    // or are we in sunset
    red = 1 - ((dayhour - (dusk - riseduration_red)) * rperc);
    green = 1 - ((dayhour - (dusk - riseduration_red)) * gperc);
    blue = 1 - ((dayhour - (dusk - riseduration_red)) * bperc);
    riseordawn = 1;
  } else {
    // or no twilight
    riseordawn = 0;
    red = green = blue = 0;
  }

  // failsafe if calculations took a wrong direction somewhere
  if (red > 1) {
    red = 1;
  }
  if (green > 1) {
    green = 1;
  }
  if (blue > 1) {
    blue = 1;
  }
  if (red < 0) {
    red = 0;
  }
  if (green < 0) {
    green = 0;
  }
  if (blue < 0) {
    blue = 0;
  }

  /* // debugging
  cout << "dayhour " << dayhour << ", lights " << lights << ", riseordawn "
       << riseordawn << ", red " << red << ", green " << green << ", blue "
       << blue << endl;
       */

  // write the calculated values to the system
  // the pins are hardcoded - that's not very
  // nice, but it works...

  filename = "/dev/shm/pin_8";
  filehandler.open(filename.c_str());
  if (filehandler.is_open()) {
    filehandler << (int)lights << endl;
    filehandler.close();
  } else {
    cout << "ERROR: could not write to " << filename << endl;
  }

  filename = "/dev/shm/pin_9";
  filehandler.open(filename.c_str());
  if (filehandler.is_open()) {
    filehandler << (int)riseordawn << endl;
    filehandler.close();
  } else {
    cout << "ERROR: could not write to " << filename << endl;
  }

  if ((red > 0) && (red < 1)) {
    filename = "/dev/pi-blaster";
    filehandler.open(filename.c_str());
    if (filehandler.is_open()) {
      filehandler << "14=" << red << endl;
      filehandler << "15=" << green << endl;
      filehandler << "18=" << blue << endl;
      filehandler.close();
    }
  }
}

struct julian calcjtimes(time_t t) {

  struct tm *current_time = gmtime(&t);
  // longitude west of magdeburg
  double low = -11.6322;
  // latitude of magdeburg
  double lam = 52.1243;
  // latitude of madagascar (if it were on northern hemishpere)
  // double lam=22.5;

  // calculate julian day number based on
  // https://de.wikipedia.org/wiki/Julianisches_Datum
  int m = current_time->tm_mon + 1;
  int y = current_time->tm_year + 1900;
  if (m <= 2) {
    m += 12;
    y--;
  }
  int d = current_time->tm_mday;
  int a = floor((y) / 100);
  double b = 2 - a + floor(a / 4);
  double jd = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5;

  // calculation of sunrise based on
  // https://en.wikipedia.org/wiki/Sunrise_equation
  // current julian day
  double n = jd - 2451545 + 0.0008;
  // mean solar noon
  double js = low / 360 + n;
  // mean anomaly
  double ma = fmod((357.5291 + 0.98560028 * js), 360);
  // equation of the center
  double c = 1.9148 * sin(ma * torad) + 0.02 * sin(2 * ma * torad) + 0.0003 * sin(3 * ma * torad);
  // ecliptic longitude
  double l = fmod((ma + c + 180 + 102.9372), 360);
  // solar transit - it seems they have forgotten the 2451545.5 on the wikipedia
  // page. or i did not understand correctly.
  double jt = 2451545.5 + js + 0.0053 * sin(ma * torad) - 0.0069 * sin(2 * l * torad);
  // declination of the sun
  double de = asin(sin(l * torad) * sin(23.44 * torad)) * todeg;
  // hour angle
  double w =
      acos((sin(-0.83 * torad) - sin(lam * torad) * sin(de * torad)) / (cos(lam * torad) * cos(de * torad))) * todeg;

  double jset = jt + w / 360;
  double jrise = jt - w / 360;

  struct julian cjt = {jrise, jset};

  return cjt;
}

int main() {
  cout << "starting up..." << endl;
  time_t now = time(0);
  struct tm *nowt;
  int nowd = localtime(&now)->tm_yday;
  int curd = nowd + 1;
  struct julian jt;

  double sunrise;
  double sunset;
  double lightson;
  double lightsoff;
  double dawn;
  double dusk;

  // better float precision for debugging purposes
  std::cout.setf(std::ios_base::fixed, std::ios_base::floatfield);
  std::cout.precision(10);

  // here is the main loop, that just loops over and over again
  while (true) {
    now = time(0);
    nowt = localtime(&now);
    nowd = nowt->tm_yday;
    if (nowd != curd) {
      cout << "a new day" << endl;
      // the day changed, so this is a new day
      curd = nowd;
      jt = calcjtimes(now);

      // now we have the correct times. first skip the acutal
      // date because i only need the times. as julian day .5 is
      // 00:00 gmt we have to subtract .5 so we get the correct
      // values for hour, minute and second.
      // they will be shifted so
      // the day of the terrarium matches the day of the owners and
      // also i want to have a nice dawn and dusk.
      // the dawn and dusk will spread evenly before and after
      // the actal sunrise

      sunrise = (jt.jrise - .5 - floor(jt.jrise - .5)) + mstep * 60;
      sunset = (jt.jset - .5 - floor(jt.jset - .5)) + mstep * 60;
      lightson = sunrise + riseduration / 2;
      lightsoff = sunset - riseduration / 2;
      dawn = sunrise - riseduration / 2;
      dusk = sunset + riseduration / 2;

      // write everything to the log
      cout << "name        julian time | utc" << endl;
      cout << "sunrise:    " << sunrise << "|" << j2h(sunrise) << endl;
      cout << "sunset:     " << sunset << "|" << j2h(sunset) << endl;
      cout << "lights on:  " << lightson << "|" << j2h(lightson) << endl;
      cout << "lights off: " << lightsoff << "|" << j2h(lightsoff) << endl;
      cout << "dawn start: " << dawn << "|" << j2h(dawn) << endl;
      cout << "dusk stop:  " << dusk << "|" << j2h(dusk) << endl;

      // write everything zo a file
      ofstream filehandler;
      string filename = "/dev/shm/terrarium_times";
      filehandler.open(filename.c_str());
      if (filehandler.is_open()) {
        filehandler << "sunrise " << sunrise << " " << j2h(sunrise) << endl;
        filehandler << "sunset " << sunrise << " " << j2h(sunset) << endl;
        filehandler << "start_dawn " << sunrise << " " << j2h(dawn) << endl;
        filehandler << "start_daylight " << sunrise << " " << j2h(lightson) << endl;
        filehandler << "stop_daylight " << sunrise << " " << j2h(lightsoff) << endl;
        filehandler << "stop_dusk " << sunrise << " " << j2h(dusk) << endl;
        filehandler.close();
      }
    }
    // sleep for a second
    usleep(1000000);
    // set the lights
    setlights(nowt->tm_hour * hstep + nowt->tm_min * mstep + nowt->tm_sec * sstep, dawn, sunrise, sunset, dusk);
  }
  // this will never be reached, but anyway
  return 0;
}
