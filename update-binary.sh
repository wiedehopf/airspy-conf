#!/bin/bash
# Update airspy_adsb binary

cd /tmp/
wget -O airspy_adsb-linux-arm.tgz https://airspy.com/downloads/airspy_adsb-linux-arm.tgz
tar xzf airspy_adsb-linux-arm.tgz
systemctl stop airspy_adsb
cp airspy_adsb /usr/local/bin/
systemctl start airspy_adsb
