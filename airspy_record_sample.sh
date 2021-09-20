#!/bin/bash

function usage() {
	echo 'sudo /usr/local/share/airspy-conf/airspy_record_sample.sh <sample_rate MHz> <gain> <seconds> <"bias" or empty>'
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

free_mem=$(free -m | grep Mem: | awk '{ print $7 }')

if [[ -z $free_mem ]]; then
	echo "FATAL: could not detemine free memory"
	exit 1
fi
if (( free_mem < 100 )); then
	echo "FATAL: Less than 100 MB of memory is free, this isn't sufficient"
	exit 1
fi

mount -t tmpfs -o size=$((free_mem - 50))m tmpfs $dir
usable_mem=$((free_mem - 100))

if [[ -n $3 ]]; then
    seconds=$3
    requested_mem=$(awk "BEGIN{ print $seconds * (1.905 * $rate); }")
    rounded_mem=$(awk "BEGIN{ print int($requested_mem); }")
    echo ---------
    if ((rounded_mem > usable_mem)); then
        echo "Requested $seconds seconds, but that would take $requested_mem MB of memory and only $usable_mem MB is available!"
        mem=$usable_mem
    else
        echo "Requested $seconds seconds, file size will be $requested_mem MB."
        mem=$usable_mem
        mem=$requested_mem
    fi
    echo ---------
else
    mem=$usable_mem
fi

if [[ $4 == bias ]]; then
    bias="-b1"
fi

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
timeout $seconds airspy_rx -r $temp -t 4 -a "${rate}000000" -f 1090 -g $gain $packing $bias || true
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
