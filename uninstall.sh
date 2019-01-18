#!/bin/bash

cp /etc/default/dump1090-fa.airspyconf /etc/default/dump1090-fa

piaware-config receiver-type ""
piaware-config receiver-host ""
piaware-config receiver-port ""


systemctl disable airspy_adsb
systemctl stop airspy_adsb
systemctl restart piaware dump1090-fa
