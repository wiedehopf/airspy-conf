#!/bin/bash
# Simple configuration for using airspy_adsb with piaware or just dump1090-fa
set -e

repository=https://raw.githubusercontent.com/wiedehopf/airspy-conf/master
#download and install the airspy_adsb binary
ARCH=arm
if dpkg --print-architecture | grep -F -e armhf &>/dev/null; then
    ARCH=arm
elif uname -m | grep -F -e arm64 -e aarch64 &>/dev/null; then
    ARCH=arm64
elif uname -m | grep -F -e arm &>/dev/null; then
    ARCH=arm
elif uname -m | grep -F -e x86_64 &>/dev/null; then
    ARCH=x86_64
else
	echo "Unable to download a program version for your platform!"
fi

function download() {
    cd /tmp/
    if ! wget -O airspy.tgz "$binary"; then
        echo "download error?!"
        exit 1
    fi
    rm -f ./airspy_adsb
    tar xzf airspy.tgz
}

URL="https://github.com/wiedehopf/airspy-conf/raw/master"
OS="buster"
binary="${URL}/${OS}/airspy_adsb-linux-${ARCH}.tgz"

download

if ! ./airspy_adsb -h &>/dev/null; then
    echo "----------------"
    echo "Seems your system is a bit old, performance may be worse than on buster or newer!"
    echo "----------------"
    OS="stretch"
    binary="${URL}/${OS}/airspy_adsb-linux-${ARCH}.tgz"
    download
    if ! ./airspy_adsb -h; then
        echo "Error, can't execute the binary, please report $(uname -m) and the above error."
        exit 1
    fi
fi

systemctl stop airspy_adsb &>/dev/null || true
cp -f airspy_adsb /usr/local/bin/

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
    sed -i -e 's/^NET.*/NET= -l 47787:beast/' /etc/default/airspy_adsb
    systemctl restart airspy_adsb
	piaware-config receiver-type relay
	piaware-config receiver-host localhost
	piaware-config receiver-port 47787
    systemctl restart piaware &>/dev/null || true
    systemctl restart dump1090-fa &>/dev/null || true
    systemctl restart beast-splitter &>/dev/null || true
else
	if ! command -v dump1090-fa &>/dev/null && ! command -v readsb &>/dev/null; then
        echo "Please install readsb or dump1090-fa before installing airspy-conf!"
        echo "https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-dump1090-fa"
        echo "https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-readsb"
        exit 1
	fi

	#configure dump1090-fa / readsb
	if [[ -f /boot/adsbx-env ]]; then
        sed -i -e 's/^RECEIVER_OPTIONS=.*/RECEIVER_OPTIONS="--net-only"/' /boot/adsbx-env
        systemctl restart readsb &>/dev/null || true
	elif systemctl is-enabled readsb &>/dev/null && ! grep -qs -e '--net-only' /etc/default/readsb; then
		LAT=$(grep -o -e '--lat [0-9]*\.[0-9]*' /etc/default/readsb | head -n1)
		LON=$(grep -o -e '--lon [0-9]*\.[0-9]*' /etc/default/readsb | head -n1)
        cp -n /etc/default/readsb /etc/default/readsb.airspyconf
        wget -q -O /etc/default/readsb $repository/readsb.default
        if [ -n "$LAT" ] && [ -n "$LON" ]; then
            sed -i "s/DECODER_OPTIONS=\"/DECODER_OPTIONS=\"$LAT $LON /" /etc/default/readsb
        fi
        systemctl restart readsb &>/dev/null || true
	elif systemctl is-enabled dump1090-fa &>/dev/null && ! grep -qs -e '--net-only' /etc/default/dump1090-fa; then
		cp -n /etc/default/dump1090-fa /etc/default/dump1090-fa.airspyconf
        if grep -qs /etc/default/dump1090-fa -e 'CONFIG_STYLE.*6'; then
            sed -i -e 's/RECEIVER.*/RECEIVER=none/' /etc/default/dump1090-fa
            sed -i -e 's/MAX_RANGE=360/MAX_RANGE=500/' /etc/default/dump1090-fa
        else
            LAT=$(grep -o -e '--lat [0-9]*\.[0-9]*' /etc/default/dump1090-fa | head -n1)
            LON=$(grep -o -e '--lon [0-9]*\.[0-9]*' /etc/default/dump1090-fa | head -n1)
            wget -q -O /etc/default/dump1090-fa $repository/dump1090-fa.default
            if [ -n "$LAT" ] && [ -n "$LON" ]; then
                sed -i "s/DECODER_OPTIONS=\"/DECODER_OPTIONS=\"$LAT $LON /" /etc/default/dump1090-fa
            fi
        fi
        systemctl restart dump1090-fa &>/dev/null || true
    fi
fi

echo "------------------------"
echo "airspy-conf install finished successfully!"
