#include <fstream>
#include <iostream>
#include <time.h>
#include <unistd.h>

using namespace std;

int main() {
  time_t now = time(0);
  struct tm *nowt;
  unsigned short state = 0;
  ofstream filehandler;
  string filename;

  // startup
  cout << "starting up ..." << endl;

  while (true) {
    now = time(0);
    nowt = localtime(&now);
    if ((nowt->tm_hour >= 12) && (nowt->tm_hour <= 13)) {
      if (state == 0) {
        cout << "It's noon now" << endl;
      }
      state = 1;
    } else {
      if (state == 1) {
        cout << "Noon is over" << endl;
      }
      state = 0;
    }
    // spot
    filename = "/dev/shm/pin_27";
    filehandler.open(filename.c_str());
    if (filehandler.is_open()) {
      filehandler << state << endl;
      filehandler.close();
    } else {
      cout << "ERROR: could not write to " << filename << endl;
    }
    // fan
    filename = "/dev/shm/pin_25";
    filehandler.open(filename.c_str());
    if (filehandler.is_open()) {
      filehandler << state << endl;
      filehandler.close();
    } else {
      cout << "ERROR: could not write to " << filename << endl;
    }
    // sleep for 10 seconds
    usleep(10000000);
  }
}
