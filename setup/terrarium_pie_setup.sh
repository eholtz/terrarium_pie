#!/bin/bash

# this script attemts to configure and install all the things needed for
# my terrarium software
# what you shoud do beforehand
# * dpkg-reconfigure locales # tmux won't work without reconfiguring locales. i usually select en_US as default and generate de_DE additionally
# * add passwordless sudo for your account. just for convenience.
# * apt -y install git
# * git clone git@github.com:eholtz/terrarium_pie.git # i do it directly in my home

curd=$(readlink -f $(dirname $0))

# mount /tmp and /var/log to ram
sudo sed -i "/\/var\/log/d" /etc/fstab
sudo sed -i "/\/tmp/d" /etc/fstab
cp /etc/fstab /tmp/fstab
cp /etc/fstab ~/fstab.$(date +%F-%T)
echo "tmpfs /var/log tmpfs size=16M 0 0" >> /tmp/fstab
echo "tmpfs /tmp tmpfs size=128M 0 0" >> /tmp/fstab
sudo chown root: /tmp/fstab
sudo mv /tmp/fstab /etc/
mount -a

# create directories
mkdir -p /tmp/setup
cd /tmp/setup

# install things i want
sudo apt -y install tmux

# install and configure chrony
# the makestep 1 -1 will not slew the clock if the
# difference is more than one second anytime
# and not just at the startup
sudo apt -y install chrony
sudo sed -i "s/^makestep.*/makestep 1 -1/" /etc/chrony/chrony.conf 
sudo systemctl enable chrony
sudo systemctl restart chrony

# install pi-blaster
sudo apt -y install autoconf
sudo apt -y install clang
git clone https://github.com/sarfata/pi-blaster.git
cd pi-blaster
git checkout -- pi-plaster.c
# my setup for the pins 14,15,18
sed -i "/static.uint8_t.known_pins.MAX_CHANNELS./,/;/c\
static uint8_t known_pins[MAX_CHANNELS] = { 14, 15, 18 };" pi-blaster.c
./autogen.sh
./configure
make
sudo make install
sudo systemctl enable pi-blaster
sudo systemctl start pi-blaster
cd /tmp/setup

# demons for the lights
daemons="lightsdaemon pincontroldaemon"
sudo apt -y install wiringpi
cd $curd/../source
cat > /tmp/template.service << EOF
[Unit]
Description=Terrarium DAEMON

[Service]
ExecStart=PATH
Restart=always

[Install]
WantedBy=getty.target
EOF
for d in $daemons ; do
  clang++ -Wall -O2 $d.cpp -o ../bin/$d
  cp /tmp/template.service /tmp/$d.service
  sed -i "s;PATH;$(readlink -f $curd/../bin/lightsdaemon);" /tmp/$d.service
  sed -i "s;DAEMON;$d;" /tmp/$d.service
  sudo mv /tmp/$d.service /etc/systemd/system/$d.service
  sudo systemctl daemon-reload
  sudo systemctl enable $d
  sudo systemctl start $d
done

# 24/7 according to https://www.datenreise.de/raspberry-pi-stabiler-24-7-dauerbetrieb/

# swap off
sudo dphys-swapfile swapoff
sudo systemctl disable dphys-swapfile
sudo apt-get -y purge dphys-swapfile

# watchdog module already loaded by default
sudo apt -y install watchdog
cat > /tmp/watchdog.conf << EOF
max-load-1      = 24
watchdog-device = /dev/watchdog
realtime        = yes
priority        = 1
EOF
sudo mv /tmp/watchdog.conf /etc/watchdog.conf
sudo systemctl enable watchdog
sudo systemctl start watchdog

sudo apt -y autoremove

