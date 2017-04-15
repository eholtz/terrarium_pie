#!/bin/bash

# check time
chronydriftfile=/var/lib/chrony/chrony.drift
if [ -f $chronydriftfile ] ; then
  if [ $(cat /var/lib/chrony/chrony.drift | awk '{print $2}' | cut -d '.' -f 1) -gt 60 ]; then
    systemctl restart chrony
  fi
fi

logfile="log/$(date +%Y%m%d.%H%M%S).runlog"
cop=$(readlink -f $0)
dir=$(dirname $cop)

date > $logfile

cd $(dirname $0)

#source functions.sh >> $logfile
source defs.sh >> $logfile
cd $dir

echo "Starte control-scripte ..." >> $logfile
echo >> $logfile

source control_licht.sh >> $logfile

#source control_waerme_ecke.sh >> $logfile
#source control_waerme_stein.sh >> $logfile
#source control_waerme_schlauch.sh >> $logfile
#source control_brunnen.sh >> $logfile
#source control_regen.sh >> $logfile
#source control_nebel.sh >> $logfile

#echo "Schalte Geckocamlader ein..." >> $logfile
#turnon 16 "geckocam.turned.on"
#turnon 16 "geckocam.turned.off"


date >> $logfile

rm log/lastlog
ln -s $(basename $logfile) log/lastlog
