#!/bin/bash
# Simple configuration for using airspy_adsb with piaware or just dump1090-fa

repository=https://raw.githubusercontent.com/wiedehopf/airspy-conf/master
#download and install the airspy_adsb binary
if uname -m | grep -F -e arm -e aarch64 &>/dev/null
then
	binary="https://airspy.com/downloads/airspy_adsb-linux-arm.tgz"
else
	binary="https://airspy.com/downloads/airspy_adsb-linux-$(uname -m).tgz"
fi
systemctl stop airspy_adsb &>/dev/null
cd /tmp/
if ! wget -q -O airspy.tgz $binary
then
	echo "Unable to download a program version for your platform!"
	exit 1
fi
tar xzf airspy.tgz
cp airspy_adsb /usr/local/bin/


#install and enable systemd service
rm -f /etc/systemd/system/airspy_adsb.service
wget -q -O /lib/systemd/system/airspy_adsb.service $repository/airspy_adsb.service
wget -q -O /etc/default/airspy_adsb $repository/airspy_adsb.default

systemctl enable airspy_adsb
systemctl restart airspy_adsb

if [[ "$1" == "only-airspy" ]]; then
	echo "airspy_adsb service installed.\n\
	Listening on port 47787 to provide beast data.\n\
	Trying to connect to port 30004 to provide beast data."
	exit 0
fi

if [ -f /boot/piaware-config.txt ]
then
	#configure piaware to custom mode
	#sed -i -e 's@beast - radarcape - relay - other@# added by airspy\n\t\tother {\n\t\t\tlappend receiverOpts "--net-only" "--net-bo-port 30005" "--fix"\n\t\t}\n\n\t\tbeast - radarcape - relay@' /usr/lib/piaware-support/generate-receiver-config
	#piaware version > 3.7
	#sed -i -e 's@none - other@# added by airspy\n\t\tother {\n\t\t\tlappend receiverOpts "--net-only" "--net-bo-port 30005" "--fix"\n\t\t}\n\n\t\tnone@' /usr/lib/piaware-support/generate-receiver-config
	sed -i 's/ -c localhost:30004:beast//' /etc/default/airspy_adsb
	piaware-config receiver-type relay
	piaware-config receiver-host localhost
	piaware-config receiver-port 47787
else
	#package install, install dump1090-fa
	if ! command dump1090-fa &>/dev/null
	then
		echo 'Installing dump1090-fa as it is required:'
		wget -q http://flightaware.com/adsb/piaware/files/packages/pool/piaware/p/piaware-support/piaware-repository_3.7.2_all.deb
		dpkg -i piaware-repository_3.7.2_all.deb
		apt update
		if ! apt install dump1090-fa; then
			echo " ----------"
			echo "airspy_adsb service installed.\n\
			Listening on port 47787 to provide beast data.\n\
			Trying to connect to port 30004 to provide beast data."
			echo " ----------"
			echo "Unable to install dump1090-fa, can't configure dump1090-fa!"
			echo "If you want to use dump1090-fa, install dump1090-fa manually and then re-run this install scrit."
			echo " ----------"
			exit 1
		fi
	fi

	#configure dump109-fa
	if dump1090-fa --help &>/dev/null;
	then
		LAT=$(grep -o -e '--lat [0-9]*\.[0-9]*' /etc/default/dump1090-fa | head -n1)
		LON=$(grep -o -e '--lon [0-9]*\.[0-9]*' /etc/default/dump1090-fa | head -n1)
		cp -n /etc/default/dump1090-fa /etc/default/dump1090-fa.airspyconf
		wget -q -O /etc/default/dump1090-fa $repository/dump1090-fa.default
		if [ -n "$LAT" ] && [ -n "$LON" ]
		then
			sed -i "s/DECODER_OPTIONS=\"/DECODER_OPTIONS=\"$LAT $LON /" /etc/default/dump1090-fa
		fi
	else
		echo "dump1090-fa needs to be installed for this script to work!"
	fi

fi


#restart relevant services
systemctl daemon-reload
systemctl kill -s 9 dump1090-fa
sleep .1
systemctl restart piaware
sleep .1
systemctl restart dump1090-fa
sleep .1
systemctl restart beast-splitter &>/dev/null
