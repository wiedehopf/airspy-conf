#!/bin/bash
# Simple configuration for using airspy_adsb with piaware or just dump1090-fa

repository=https://raw.githubusercontent.com/wiedehopf/airspy-conf/master
#download and install the airspy_adsb binary
systemctl stop airspy_adsb
cd /tmp/
wget -q -O airspy_adsb-linux-arm.tgz https://airspy.com/downloads/airspy_adsb-linux-arm.tgz
tar xzf airspy_adsb-linux-arm.tgz
cp airspy_adsb /usr/local/bin/


#install and enable systemd service
wget -q -O /etc/systemd/system/airspy_adsb.service $repository/airspy_adsb.service
wget -q -O /etc/default/airspy_adsb $repository/airspy_adsb.default
mkdir /usr/share/airspy_adsb &>/dev/null
wget -q -O /usr/share/airspy_adsb/beast_restart.sh $repository/beast_restart.sh
systemctl enable airspy_adsb


if [ -f /boot/piaware-config.txt ]
then
	#configure piaware to relay mode
	piaware-config receiver-type relay
	piaware-config receiver-host localhost
	piaware-config receiver-port 29999
else
	#package install, install beast-splitter
	if ! apt install beast-splitter
	then
		wget -q http://flightaware.com/adsb/piaware/files/packages/pool/piaware/p/piaware-support/piaware-repository_3.6.3_all.deb
		dpkg -i piaware-repository_3.6.3_all.deb
		apt update
		apt install beast-splitter
	fi

	#configure beast-splitter
	wget -q -O /etc/default/beast-splitter $repository/beast-splitter.default
	systemctl enable beast-splitter

	#configure dump109-fa
	if dump1090-fa --help &>/dev/null;
	then
		cp -n /etc/default/dump1090-fa /etc/default/dump1090-fa.airspyconf
		wget -q -O /etc/default/dump1090-fa $repository/dump1090-fa.default
	fi

fi


#restart relevant services
systemctl daemon-reload
systemctl kill -s 9 dump1090-fa
sleep 1
systemctl restart airspy_adsb
sleep .1
systemctl restart piaware dump1090-fa
