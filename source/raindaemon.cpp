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

int main() {
  time_t now = time(0);
  struct tm *nowt = localtime(&now);
  unsigned short state = 0, laststate = 0;
  ofstream outhandler;
  ifstream inhandler;
  char buffer[128];
  unsigned short rainprobability = 256 / 4;
  unsigned long rainduration = 0;
  unsigned int rainstartsecond = 0, currentsecond = 0;
  string line;

  // startup
  cout << "starting up ..." << endl;
  cout << "creating rain directory" << endl;
  // mkdir did not work for some strange reason, so I'm lazy
  snprintf(buffer, sizeof(buffer), "mkdir -p /dev/shm/rain/");
  system(buffer);
  // calculate all rain times for the complete year
  // the seed is the actual year so we have persistent
  // states across reboots
  cout << "calculating rain days ... " << endl;
  srand(nowt->tm_year);
  for (int i = 0; i < 365; i++) {
    // cout << i << endl;
    if ((rand() % 255) < rainprobability) {
      state = 1;
      rainduration = rand() % 60 * 3 + 60;
      // we will rain between 13:00 and 18:00
      // so we will never start when the noon light is on
      // heating should recognize rain events and act
      // accordingly
      rainstartsecond = (13 + rand() % 4) * 3600 + rand() % 60 * 60 + rand() % 60;
      rainprobability = 0;
    } else {
      rainduration = 0;
      rainstartsecond = 0;
      rainprobability += 256 / 4;
    }
    snprintf(buffer, sizeof(buffer), "/dev/shm/rain/%d", i);
    outhandler.open(buffer);
    if (outhandler.is_open()) {
      outhandler << rainduration << endl;
      outhandler << rainstartsecond << endl;
      outhandler.close();
    } else {
      cout << "ERROR: could not write to " << buffer << endl;
    }
  }
  cout << "calculating done." << endl;

  // init the file with 0
  writepin(0);

  // now the loop starts :-)
  while (true) {
    now = time(0);
    nowt = localtime(&now);
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
    }
    // sleep for 10 seconds
    usleep(10000000);
  }
}