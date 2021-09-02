#!/bin/bash
set -e

mv /etc/default/dump1090-fa.airspyconf /etc/default/dump1090-fa &>/dev/null || true
mv /etc/default/readsb.airspyconf /etc/default/readsb &>/dev/null || true

if [ -f /usr/lib/piaware-support/generate-receiver-config ]; then
    sed -i -e '/# added by airspy/,+4d' /usr/lib/piaware-support/generate-receiver-config
    sed -i -e 's/beast - radarcape - relay/beast - radarcape - relay - other/' /usr/lib/piaware-support/generate-receiver-config
fi

if [ -f /boot/piaware-config.txt ]; then
    piaware-config receiver-type ""
    piaware-config receiver-host "127.0.0.1"
    piaware-config receiver-port "30005"
fi

systemctl disable airspy_adsb
systemctl stop airspy_adsb
systemctl is-enabled piaware &>/dev/null && systemctl restart --no-block piaware || true
systemctl is-enabled dump1090-fa &>/dev/null && systemctl restart --no-block dump1090-fa || true
systemctl is-enabled readsb &>/dev/null && systemctl restart --no-block readsb || true

echo "------------------------"
echo "airspy-conf uninstall finished successfully!"
