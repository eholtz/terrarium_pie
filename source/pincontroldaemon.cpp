#include <fstream>
#include <iostream>
#include <stdlib.h>
#include <string>
#include <unistd.h>

using namespace std;

// number of known pins
#define MAX_PIN 6

// pins to control
// wiring pi pins
static unsigned short known_pins[MAX_PIN] = {
    0,  // spot corner
    2,  // heating coil
    7,  // spot stone
    8,  // daylight tubes
    9,  // 12v ac for dusk/dawn
    12, // rain machine
};

int main() {
  unsigned short i = 0;
  char buffer[128];
  string line;
  unsigned short state = 0;

  // startup
  cout << "starting up ..." << endl;

  // init pins
  for (i = 0; i < MAX_PIN; i++) {
    cout << "init pin " << known_pins[i] << " for output" << endl;
    snprintf(buffer, sizeof(buffer), "/usr/bin/gpio mode %d out", known_pins[i]);
    system(buffer);
  }

  // main loop
  while (true) {
    for (i = 0; i < MAX_PIN; i++) {
      snprintf(buffer, sizeof(buffer), "/dev/shm/pin_%d", known_pins[i]);
      ifstream pininput(buffer);
      if (pininput.is_open()) {
        getline(pininput, line);
        if (line.compare(0,1,"1")==0) {
          state = 1;
        } else {
          state = 0;
        }
        snprintf(buffer, sizeof(buffer), "/usr/bin/gpio write %d %d", known_pins[i], state);
        system(buffer);
        pininput.close();
      }
    }
    // sleep for 5 seconds
    usleep(5000000);
  }
}