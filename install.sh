#!/bin/bash
# Simple configuration for using airspy_adsb with piaware or just dump1090-fa
set -e

repository=https://raw.githubusercontent.com/wiedehopf/airspy-conf/master
#download and install the airspy_adsb binary
if dpkg --print-architecture | grep -F -e armhf &>/dev/null; then
	binary="https://airspy.com/downloads/airspy_adsb-linux-arm.tgz"
elif uname -m | grep -F -e arm64 -e aarch64 &>/dev/null; then
	binary="https://airspy.com/downloads/airspy_adsb-linux-arm64.tgz"
elif uname -m | grep -F -e arm &>/dev/null; then
	binary="https://airspy.com/downloads/airspy_adsb-linux-arm.tgz"
else
	binary="https://airspy.com/downloads/airspy_adsb-linux-$(uname -m).tgz"
fi

systemctl stop airspy_adsb &>/dev/null || true
cd /tmp/
if ! wget -q -O airspy.tgz "$binary"; then
	echo "Unable to download a program version for your platform!"
	exit 1
fi
tar xzf airspy.tgz
cp airspy_adsb /usr/local/bin/

#install and enable systemd service
rm -f /etc/systemd/system/airspy_adsb.service
wget -q -O /lib/systemd/system/airspy_adsb.service $repository/airspy_adsb.service
wget -q -O /etc/default/airspy_adsb $repository/airspy_adsb.default

if ! command -v /usr/bin/taskset &>/dev/null; then
	sed -i -e 's?/usr/bin/taskset.*AFFINITY ??' /lib/systemd/system/airspy_adsb.service
fi

systemctl enable airspy_adsb
systemctl restart airspy_adsb

if [[ "$1" == "only-airspy" ]]; then
	printf "airspy_adsb service installed.\n\
	Listening on port 47787 to provide beast data.\n\
	Trying to connect to port 30004 to provide beast data."
	exit 0
fi

if [[ -f /boot/piaware-config.txt ]] && { piaware-config -show manage-config | grep -qs yes; }; then
	#configure piaware to custom mode
	#sed -i -e 's@beast - radarcape - relay - other@# added by airspy\n\t\tother {\n\t\t\tlappend receiverOpts "--net-only" "--net-bo-port 30005" "--fix"\n\t\t}\n\n\t\tbeast - radarcape - relay@' /usr/lib/piaware-support/generate-receiver-config
	#piaware version > 3.7
	#sed -i -e 's@none - other@# added by airspy\n\t\tother {\n\t\t\tlappend receiverOpts "--net-only" "--net-bo-port 30005" "--fix"\n\t\t}\n\n\t\tnone@' /usr/lib/piaware-support/generate-receiver-config
	sed -i 's/ -c localhost:30004:beast//' /etc/default/airspy_adsb
	piaware-config receiver-type relay
	piaware-config receiver-host localhost
	piaware-config receiver-port 47787
else
	if ! command -v dump1090-fa &>/dev/null && ! command -v readsb &>/dev/null; then
        echo "Please install readsb or dump1090-fa before installing airspy-conf!"
        echo "https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-dump1090-fa"
        echo "https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-readsb"
        exit 1
	fi

	#configure dump1090-fa / readsb
	if command -v dump1090-fa &>/dev/null; then
		LAT=$(grep -o -e '--lat [0-9]*\.[0-9]*' /etc/default/dump1090-fa | head -n1)
		LON=$(grep -o -e '--lon [0-9]*\.[0-9]*' /etc/default/dump1090-fa | head -n1)
		cp -n /etc/default/dump1090-fa /etc/default/dump1090-fa.airspyconf
		wget -q -O /etc/default/dump1090-fa $repository/dump1090-fa.default
		if [ -n "$LAT" ] && [ -n "$LON" ]; then
			sed -i "s/DECODER_OPTIONS=\"/DECODER_OPTIONS=\"$LAT $LON /" /etc/default/dump1090-fa
		fi
    fi
	if command -v readsb &>/dev/null; then
		LAT=$(grep -o -e '--lat [0-9]*\.[0-9]*' /etc/default/readsb | head -n1)
		LON=$(grep -o -e '--lon [0-9]*\.[0-9]*' /etc/default/readsb | head -n1)
		cp -n /etc/default/readsb /etc/default/readsb.airspyconf
		wget -q -O /etc/default/readsb $repository/readsb.default
		if [ -n "$LAT" ] && [ -n "$LON" ]; then
			sed -i "s/DECODER_OPTIONS=\"/DECODER_OPTIONS=\"$LAT $LON /" /etc/default/readsb
		fi
	fi
fi

#restart relevant services
systemctl daemon-reload
systemctl kill -s 9 dump1090-fa &>/dev/null || true
systemctl kill -s 9 readsb &>/dev/null || true
sleep .1
systemctl restart piaware &>/dev/null || true
sleep .1
systemctl restart dump1090-fa &>/dev/null || true
systemctl restart readsb &>/dev/null || true
sleep .1
systemctl restart beast-splitter &>/dev/null || true


echo "------------------------"
echo "airspy-conf install finished successfully!"
