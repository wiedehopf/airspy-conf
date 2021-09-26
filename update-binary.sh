#!/bin/bash
# Update airspy_adsb binary
set -e

ARCH=arm
if dpkg --print-architecture | grep -F -e armhf &>/dev/null; then
    ARCH=arm
elif uname -m | grep -F -e arm64 -e aarch64 &>/dev/null; then
    ARCH=arm64
elif uname -m | grep -F -e arm &>/dev/null; then
    ARCH=arm
elif uname -m | grep -F -e x86_64 &>/dev/null; then
    ARCH=x86_64
    if cat /proc/cpuinfo | grep flags | grep popcnt | grep sse4_2 &>/dev/null; then
        ARCH=nehalem
    fi
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
        echo "ARCH=${ARCH} Error, can't execute the binary, please report $(uname -m) and the above error."
        exit 1
    fi
fi

systemctl stop airspy_adsb &>/dev/null || true
cp -f airspy_adsb /usr/local/bin/

systemctl restart airspy_adsb

echo "------------------------"
echo "airspy-conf update finished successfully!"
