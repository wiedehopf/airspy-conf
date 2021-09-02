#!/bin/bash

function usage() {
	echo "sudo /usr/local/share/airspy-conf/airspy_record_sample.sh <sample_rate MHz> <gain> <raw_size_MB>"
	exit 1
}

set -e

if [ "$(id -u)" != "0" ]; then
	echo You must use sudo or be root to run this script!
	usage
fi

if ! command -v airspy_rx &>/dev/null || ! command -v curl &>/dev/null; then
	echo please: sudo apt install airspy -y
	exit 1
fi

rate=$1
if [[ $rate != 12 ]] && [[ $rate != 20 ]] && [[ $rate != 24 ]]; then
	echo choose 12, 20, or 24 as a rate to use
	usage
fi
gain=$2
if ! (( gain < 22 )) && ! (( gain > 0 )); then
	echo invalid gain
	usage
fi

dir=/media/airspy_sample
mkdir -p $dir
temp=$dir/sample.bin

rm -rf $temp

mem=$(free -m | grep Mem: | awk '{ print $7 }')

if [[ -z $mem ]] || (( mem < 500 )); then
	echo "not enough memory available"
	exit 1
fi
mem=$((mem - 100))

if [[ -n $3 ]] && ((mem > $3)); then
    mem=$3
fi


mount -t tmpfs -o size=$(( mem + 50))m tmpfs $dir

seconds=$(awk "BEGIN{ print $mem / (1.905 * $rate); }")


packing=""
if [[ $rate == 24 ]]; then
	packing="-p1"
fi
systemctl stop airspy_adsb
echo ---------
echo Stopping airspy_adsb, recording $seconds seconds
echo ---------
set -x
timeout $seconds airspy_rx -r $temp -t 4 -a "${rate}000000" -f 1090 -g $gain $packing || true
set +x
echo ---------
echo Starting airspy_adsb, your station will resume reception!
systemctl --no-block restart airspy_adsb
echo
echo ---------
echo "Sample has been save here: $temp"
echo "You can run decoding tests on it using the airspy_adsb -F option."
echo "Example command:"
echo "airspy_adsb -v -F /media/airspy_sample/sample.bin -f 1 -w 5 -e 20 -m ${rate}"
