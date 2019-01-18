#!/bin/bash
# Simple configuration for using airspy_adsb with piaware or just dump1090-fa

cd /tmp/
wget -O airspy_adsb-linux-arm.tgz https://airspy.com/downloads/airspy_adsb-linux-arm.tgz
tar xzf airspy_adsb-linux-arm.tgz
cp airspy_adsb /usr/local/bin/

cat >/etc/systemd/system/airspy_adsb.service <<EOF
[Unit]
Description=Airspy ADS-B receiver
Documentation=https://discussions.flightaware.com/t/howto-airspy-mini-piaware-dump1090-fa-configuration/44343/2

[Service]
EnvironmentFile=/etc/default/airspy_adsb
ExecStart=/usr/local/bin/airspy_adsb \$NET \$OPTIONS \$G \$GAIN \$M \$SAMPLE_RATE
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=airspy_adsb
User=root
Group=root
Environment=NODE_ENV=production
Nice=-19

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/default/airspy_adsb <<EOF
#network settings
NET="-l 30005:beast -c localhost:30104:beast"

#gain is 0 to 21, each step of gain is equivalent to about 3dB, so reduce in increments of 1 if 21 is too high
GAIN=21

#other options
OPTIONS="-f 1 -x -p"

#sample rate can be 12 or 20, 20 may not work depending on the system
SAMPLE_RATE=12


#don't change:
G="-g"
M="-m"
EOF


if dump1090-fa --help &>/dev/null;
then
cp -n /etc/default/dump1090-fa /etc/default/dump1090-fa.airspyconf
cat >/etc/default/dump1090-fa <<EOF
# dump1090-fa configuration
# This is read by the systemd service file as an environment file,
# and evaluated by some scripts as a POSIX shell fragment.

# If you are using a PiAware sdcard image, this config file is regenerated
# on boot based on the contents of piaware-config.txt; any changes made to this
# file will be lost.

RECEIVER_OPTIONS="--net-only"
DECODER_OPTIONS="--max-range 360"
NET_OPTIONS="--net --net-heartbeat 60 --net-ro-size 1000 --net-ro-interval 1 --net-ri-port 0 --net-ro-port 30002 --net-sbs-port 30003 --net-bi-port 30004,30104 --net-bo-port 0"
JSON_OPTIONS="--json-location-accuracy 1"
EOF

fi

if piaware-config &>/dev/null;
then
	piaware-config receiver-type other
	piaware-config receiver-host localhost
	piaware-config receiver-port 30005
fi

systemctl daemon-reload
systemctl enable airspy_adsb
systemctl restart airspy_adsb piaware dump1090-fa
