#!/bin/bash
set -e

gain="$1"

if [[ -z $gain ]] || (( $gain < 0 )) || (( $gain > 21)); then
    echo "Invalid argument, valid gain settings: 0 to 21"
    exit 1
fi

if ! grep -qs /etc/default/airspy_adsb -e '^GAIN'; then
    echo "Config file /etc/default/airspy_adsb is not in the expected format, rerun the airspy-conf install script please."
    exit 1
fi

echo "old setting: $(grep -e '^GAIN' /etc/default/airspy_adsb)"

sed -i -e "s/^GAIN.*/GAIN= $gain/" /etc/default/airspy_adsb

echo "new setting: $(grep -e '^GAIN' /etc/default/airspy_adsb)"

systemctl restart --no-block airspy_adsb

if systemctl is-active --quiet readsb; then
    systemctl restart --no-block readsb
elif systemctl is-active --quiet dump1090-fa; then
    systemctl restart --no-block dump1090-fa
fi

sleep 0.5

journalctl _SYSTEMD_INVOCATION_ID=$(systemctl show -p InvocationID --value airspy_adsb) | grep "Decoding started"
