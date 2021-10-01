#!/bin/bash
# Update airspy_adsb binary
set -e

verlte() {
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

libc=$(ldconfig -v 2>/dev/null | grep libc-2 | tail -n1 | cut -d'>' -f2 | tr -d " ")

ARCH=arm
if dpkg --print-architecture | grep -F -e armhf &>/dev/null; then
    ARCH=arm
elif uname -m | grep -F -e arm64 -e aarch64 &>/dev/null; then
    ARCH=arm64
elif uname -m | grep -F -e arm &>/dev/null; then
    ARCH=arm
elif dpkg --print-architecture | grep -F -e i386 &>/dev/null; then
    ARCH=i386
elif uname -m | grep -F -e x86_64 &>/dev/null; then
    ARCH=x86_64
    if cat /proc/cpuinfo | grep flags | grep popcnt | grep sse4_2 &>/dev/null; then
        ARCH=nehalem
    fi
else
	echo "Unable to download a program version for your platform!"
fi


URL="https://github.com/wiedehopf/airspy-conf/raw/master"

OS="buster"
required_libc="libc-2.28.so"
if verlt "$libc" "libc-2.28.so"; then
    OS="stretch"
    echo "----------------"
    echo "Seems your system is a bit old, performance may be worse than on buster or newer!"
    echo "$libc <= $required_libc"
    echo "----------------"
fi

binary="${URL}/${OS}/airspy_adsb-linux-${ARCH}.tgz"

function download() {
    cd /tmp/
    if ! wget -O airspy.tgz "$binary"; then
        echo "download error?!"
        exit 1
    fi
    rm -f ./airspy_adsb
    tar xzf airspy.tgz
}

download

if ! ./airspy_adsb -h &>/dev/null; then
    echo "ARCH=${ARCH} libc=${libc} Error, can't execute the binary, please report $(uname -m) and the above error."
    exit 1
fi


# ------------------------------

systemctl stop airspy_adsb &>/dev/null || true
cp -f airspy_adsb /usr/local/bin/

systemctl restart airspy_adsb

echo "------------------------"
echo "airspy-conf update finished successfully!"
