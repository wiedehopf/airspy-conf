#!/bin/bash

function usage() {
	echo "/usr/local/share/airspy-conf/airspy_check_narrow.sh <rate in MHz>"
	exit 1
}

set -e

if [[ -z $1 ]]; then
    usage
fi
rate=$1

dir=/media/airspy_sample
temp=$dir/sample.bin

echo Running tests on the sample file, this will take a moment!
echo -----------

command="airspy_adsb -v -f 1 -w 5 -e 20 -m ${rate} -F $temp -B narrow"
echo "Testing -B narrow using this commandline: $command"
nice $command
echo -----------

command="airspy_adsb -v -f 1 -w 5 -e 20 -m ${rate} -F $temp -B wide"
echo "Testing -B wide using this commandline: $command"
nice $command
echo -----------
echo Done!
echo -----------

