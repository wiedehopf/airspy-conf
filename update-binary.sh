#!/bin/bash
# Update airspy_adsb binary

cd /tmp/
wget -O airspy_adsb-linux-arm.tgz https://airspy.com/downloads/airspy_adsb-linux-arm.tgz
tar xzf airspy_adsb-linux-arm.tgz
cp airspy_adsb /usr/local/bin/
