#!/bin/bash
set -e

from=$1
to=$2
ival=$3

gains=$(seq $1 $2)

for i in $gains; do
    /usr/local/share/airspy-conf/airspy_adsb_gain.sh $i
    echo "Next gain change in $ival minutes."
    sleep $((ival * 60))
done
