#!/bin/bash

curd=$(readlink -f $(dirname $0))

mkdir -p /tmp/setup
cd /tmp/setup

# install pi-blaster
sudo apt -y install autoconf
sudo apt -y install clang
git clone https://github.com/sarfata/pi-blaster.git
cd pi-blaster
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
cd $curd/../source/sunrise/
clang++ -Wall -O2 lightsdaemon.cpp -o ../../bin/lightsdaemon
cat > /tmp/lightsdaemon.service << EOF
[Unit]
Description=Lights control daemon

[Service]
ExecStart=PATH

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



