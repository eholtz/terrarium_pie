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
source control_regen.sh >> $logfile
#source control_nebel.sh >> $logfile

echo "Schalte Geckocamlader ein..." >> $logfile
turnon 16 "geckocam.turned.on"
#turnon 16 "geckocam.turned.off"


date >> $logfile

rm log/lastlog
ln -s $(basename $logfile) log/lastlog
