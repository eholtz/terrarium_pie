#!/bin/bash


# this script attemts to configure and install all the things needed for
# my terrarium software
# what you shoud do beforehand
# * dpkg-reconfigure locales # tmux won't work without reconfiguring locales. i usually select en_US as default and generate de_DE additionally
# * add passwordless sudo for your account. just for convenience.
# * apt -y install git
# * git clone git@github.com:eholtz/terrarium_pie.git # i do it directly in my home

curd=$(readlink -f $(dirname $0))

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

# demon for the lights
sudo apt -y install wiringpi
cd $curd/../source
clang++ -Wall -O2 lightsdaemon.cpp -o ../../bin/lightsdaemon
cat > /tmp/lightsdaemon.service << EOF
[Unit]
Description=Lights control daemon

[Service]
ExecStart=PATH
Restart=always

[Install]
WantedBy=getty.target
EOF
sed -i "s;PATH;$(readlink -f $curd/../bin/lightsdaemon);" /tmp/lightsdaemon.service
sudo mv /tmp/lightsdaemon.service /etc/systemd/system/lightsdaemon.service
sudo systemctl daemon-reload
sudo systemctl enable lightsdaemon
sudo systemctl start lightsdaemon

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



