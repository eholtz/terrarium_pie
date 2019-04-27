#include <fstream>
#include <iostream>
#include <stdlib.h>
#include <string>
#include <unistd.h>

using namespace std;

// number of known pins
#define MAX_PIN 4

// pins to control
// wiring pi pins
static unsigned short known_pins[MAX_PIN] = {
    27,  // sun spot
    29,  // daylight tubes
    25,  // fan
    28,  // 12v ac for dusk/dawn
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
  int status = 0;
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
        status = system(buffer);
        pininput.close();
	// cout << "forcing " << state << " on pin " << known_pins[i] << " with status code " << status << endl; 
      }
    }
    // sleep for 5 seconds
    usleep(5000000);
  }
}
