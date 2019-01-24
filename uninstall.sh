#!/bin/bash

mv /etc/default/dump1090-fa.airspyconf /etc/default/dump1090-fa

piaware-config receiver-type ""
piaware-config receiver-host ""
piaware-config receiver-port ""


systemctl disable airspy_adsb
systemctl disable beast-splitter
systemctl stop airspy_adsb beast-splitter
systemctl restart piaware dump1090-fa
