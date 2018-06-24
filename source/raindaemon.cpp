#include <fstream>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <time.h>
#include <unistd.h>

using namespace std;

void writepin(int state) {
  ofstream filehandler;
  string filename = "/dev/shm/pin_12";
  filehandler.open(filename.c_str());
  if (filehandler.is_open()) {
    filehandler << state << endl;
    filehandler.close();
  } else {
    cout << "ERROR: could not write to " << filename << endl;
  }
}

void createraindays() {
  // we use the current year as seed
  time_t now = time(0);
  struct tm *nowt = localtime(&now);

  // we will have to do every day of the year
  // and we'll let c++ do the calculation for us
  time_t calctime = time(0);
  struct tm *calctimet;

  // buffer for filename and the actual
  // file handler
  char buffer[128];
  ofstream outhandler;

  // definition of rain times.
  // rainpause = 4 => it will rain about every 4 days
  // raindurationmin/raindurationmax is in seconds
  // rainstarthour/rainstophour should be configured in
  // a way it does not interfere with the noon light
  static unsigned short RAINPROBMAX = 256;
  static unsigned short RAINPAUSE = 4;
  static unsigned short DURATIONMIN = 60;
  static unsigned short DURATIONMAX = 240;
  static unsigned short RAINSTARTOUR = 13;
  static unsigned short RAINSTOPHOUR = 20;

  unsigned short rainprobability = RAINPROBMAX / RAINPAUSE;
  unsigned long rainduration = 0;
  unsigned int rainstartsecond = 0;
  unsigned short state = 0;

  cout << "creating rain directory" << endl;
  // mkdir did not work for some strange reason, so I'm lazy
  snprintf(buffer, sizeof(buffer), "mkdir -p /dev/shm/rain/");
  system(buffer);
  // calculate all rain times for the complete year
  // the seed is the actual year so we have persistent
  // states across reboots
  cout << "calculating rain days ... " << endl;
  srand(nowt->tm_year);
  calctimet = localtime(&calctime);
  calctimet->tm_yday = 0;
  calctimet->tm_hour = 1;
  calctimet->tm_min = 0;
  calctimet->tm_sec = 0;
  calctime = mktime(calctimet);
  while (calctimet->tm_year == nowt->tm_year) {
    // cout << i << endl;
    if ((rand() % RAINPROBMAX) < rainprobability) {
      state = 1;
      rainduration = rand() % (DURATIONMAX - DURATIONMIN) + DURATIONMIN;
      // because we will add a random hour to the calculated value
      // we have to subtract one from the difference of rainstop and
      // rainstart
      rainstartsecond =
          (RAINSTARTOUR + rand() % (RAINSTOPHOUR - RAINSTARTOUR - 1)) * 3600 + rand() % 60 * 60 + rand() % 60;
      rainprobability = 0;
    } else {
      rainduration = 0;
      rainstartsecond = 0;
      rainprobability += RAINPROBMAX / RAINPAUSE;
    }
    snprintf(buffer, sizeof(buffer), "/dev/shm/rain/%d", calctimet->tm_yday);
    outhandler.open(buffer);
    if (outhandler.is_open()) {
      outhandler << rainduration << endl;
      outhandler << rainstartsecond << endl;
      outhandler.close();
    } else {
      cout << "ERROR: could not write to " << buffer << endl;
    }
    // we add two seconds more to each day to
    // compensate for leap seconds. this may be a bit overkill
    // but, hey ...
    // it will not be a problem in the long run, because we only
    // calculate times for one year and we only have 366*2 seconds
    // (leap year) which is less than a day.
    calctime += 86402;
    calctimet = localtime(&calctime);
  }
  cout << "calculating done." << endl;
}

int main() {
  time_t now = time(0);
  struct tm *nowt = localtime(&now);
  time_t start = time(0);
  struct tm *startt = localtime(&start);
  unsigned long rainduration = 0;
  unsigned int rainstartsecond = 0, currentsecond = 0;
  unsigned short state = 0, laststate = 0;
  ifstream inhandler;
  char buffer[128];
  string line;

  // startup
  cout << "starting up ..." << endl;

  // init the file with 0
  writepin(0);

  // now the loop starts :-)
  while (true) {
    now = time(0);
    nowt = localtime(&now);
    // compensate for a new year
    if (startt->tm_year!=nowt->tm_year) {
      createraindays();
    }
    currentsecond = nowt->tm_hour * 3600 + nowt->tm_min * 60 + nowt->tm_sec;
    snprintf(buffer, sizeof(buffer), "/dev/shm/rain/%d", nowt->tm_yday);
    inhandler.open(buffer);
    if (inhandler.is_open()) {
      // read two lines from the file and convert them to long
      // the file format is well defined
      getline(inhandler, line);
      rainduration = strtol(line.c_str(), NULL, 10);
      getline(inhandler, line);
      rainstartsecond = strtol(line.c_str(), NULL, 10);
      inhandler.close();

      // check if we should set the pin to 1
      state = 0;
      if (rainduration > 0) {
        if ((currentsecond >= rainstartsecond) && (currentsecond < rainstartsecond + rainduration)) {
          state = 1;
        }
      }

      // cool down for ten seconds every minute
      if ((nowt->tm_sec >= 0) && (nowt->tm_sec < 10)) {
        state = 0;
      }

      // log and actual write of file
      if (laststate != state) {
        cout << "toggling state to " << state << endl;
        laststate = state;
        writepin(state);
      }
    } else {
      cout << "ERROR: could not read from " << buffer << endl;
      cout << "trying to recalculate rain days" << endl;
      createraindays();
    }
    // sleep for 10 seconds
    usleep(10000000);
  }
}