#!/bin/bash

logfile="log/$(date +%Y%m%d.%H%M%S).runlog"

date > $logfile

cd $(dirname $0)

source functions.sh >> $logfile
source defs.sh >> $logfile

echo "Starte control-scripte ..." >> $logfile
echo >> $logfile

source control_licht.sh >> $logfile
source control_waerme_ecke.sh >> $logfile
source control_waerme_stein.sh >> $logfile
source control_waerme_schlauch.sh >> $logfile
source control_brunnen.sh >> $logfile
#source control_regen.sh >> $logfile
#source control_nebel.sh >> $logfile

echo "Checke Umlaufpumpe ..." >> $logfile
turnon 23 "umlaufpumpe.turned.on"

date >> $logfile

rm lastlog
ln -s $logfile lastlog
