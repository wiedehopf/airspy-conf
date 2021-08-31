#!/bin/bash

function usage() {
	echo "sudo bash /tmp/airspy_upload_sample.sh <name> <sample_rate MHz> <gain> <raw_size_MB>"
	exit 1
}

set -e

if [ "$(id -u)" != "0" ]; then
	echo You must use sudo or be root to run this script!
	usage
fi

if ! command -v airspy_rx &>/dev/null || ! command -v curl &>/dev/null; then
	echo please: sudo apt install airspy curl -y
	exit 1
fi

name=$1
if [[ -z $name ]]; then
	echo no name given
	usage
fi
rate=$2
if [[ $rate != 12 ]] && [[ $rate != 20 ]] && [[ $rate != 24 ]]; then
	echo choose 12, 20, or 24 as a rate to use
	usage
fi
gain=$3
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

if [[ -n $4 ]] && ((mem > $4)); then
    mem=$4
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
echo Compressing / uploading file, this might take a bit!
echo -----------

file=/tmp/sample_$rate_$gain.bin.gz
URL="https://transfer.sh/${name}_r${rate}_g${gain}_$(date -u +%Y-%m-%d_%H-%M).bin.gz"
gzip -3 -c $temp | curl -H "Max-Days: 1" --upload-file "-" "$URL" | tee /dev/null
rm -rf $temp

echo
echo -----------
echo "Please give the above URL to whoever requested the sample! :)"
echo -----------

