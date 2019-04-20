#!/bin/bash
# Update airspy_adsb binary

if uname -m | grep -i arm &>/dev/null
then
	binary="https://airspy.com/downloads/airspy_adsb-linux-arm.tgz"
else
	binary="https://airspy.com/downloads/airspy_adsb-linux-$(uname -m).tgz"
fi

cd /tmp/
if ! wget -O airspy.tgz $binary
then
	echo "Unable to download a program version for your platform!"
	exit 1
fi
tar xzf airspy.tgz
systemctl stop airspy_adsb dump1090-fa	
cp airspy_adsb /usr/local/bin/
systemctl restart airspy_adsb dump1090-fa
