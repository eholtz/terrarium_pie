#!/bin/bash

### BEGIN INIT INFO
# Provides:          init relais
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Relais init
# Description:       This inits all 8 relais connected to the pi with value 0
### END INIT INFO

# Author: Eike Holtz

pins="11 12 13 15 16 17 23 24 5 6 26"

for i in $(echo $pins); do gpio -g mode $i out ; done
for i in $(echo $pins); do gpio -g write $i 1 && sleep 0.5 ; done
#for i in $(seq 11 18); do gpio -g write $i 0 && sleep 0.1 ; done
#for i in $(seq 11 18); do gpio -g write $i 1 && sleep 0.1 ; done
