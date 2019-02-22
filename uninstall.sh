#!/bin/bash

mv /etc/default/dump1090-fa.airspyconf /etc/default/dump1090-fa

if [ -f /usr/lib/piaware-support/generate-receiver-config ]
then
	sed -i -e '/# added by airspy/,+4d' /usr/lib/piaware-support/generate-receiver-config
	sed -i -e 's/beast - radarcape - relay/beast - radarcape - relay - other/' /usr/lib/piaware-support/generate-receiver-config
fi

piaware-config receiver-type ""
piaware-config receiver-host ""
piaware-config receiver-port ""


systemctl disable airspy_adsb
systemctl stop airspy_adsb
systemctl restart piaware dump1090-fa
