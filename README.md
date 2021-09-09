# airspy-conf

This script changes the piaware configuration, dump1090-fa / readsb configuration and installs a systemd-service to automatically run airspy_adsb.
I have tested the script locally, it should work. But such things sometimes don't work as intended, keep that in mind.

In case your Airspy was purchased earlier than 2017, you will probably need to update its firmware, see the note in regards to ADS-B on the quick start page: https://airspy.com/quickstart/

dump1090-fa or readsb needs to be installed before you run this script otherwise the script can't change the configuration.
It should work very well for example on a piaware-sd card image :)
A normal Raspbian sd card image also works well.

If you are on a normal PC laptop and not on an RPi, i'd recommend using readsb instead of dump1090-fa:
https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-readsb

Generally readsb might be nicer than dump1090-fa. Just to reiterate, this needs to be done before running this script.
Or you can rerun this install script after installing readsb. You'll have to reconfigure airspy_adsb as this install overwrites the configuration.

Content:

* [Installation](https://github.com/wiedehopf/airspy-conf#installation)
* [Other feeders](https://github.com/wiedehopf/airspy-conf#other-feeders)
* [Changing airspy options](https://github.com/wiedehopf/airspy-conf#Changing-airspy_adsb-options)
* [Uninstall](https://github.com/wiedehopf/airspy-conf#Uninstall)
* [Update](https://github.com/wiedehopf/airspy-conf#Update)

---

## Installation

Overwrites the configuration at /etc/default/airspy_adsb

```shell
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/install.sh)"
```

In case you're an advanced user and don't want dump1090-fa / readsb to be re-configured for some reason, you can download the script and run it like this:

```shell
sudo bash install.sh only-airspy
```

## Update

Update / download airspy_adsb to /usr/local/bin while preserving options in /etc/default/airspy_adsb

```shell
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/update-binary.sh)"
```


---

## Changing airspy_adsb options

If you want to change the airspy options, edit the option file:

```shell
sudo nano /etc/default/airspy_adsb
```

For example you might want to enable the bias tee, just add `-b` at the end of the options line so it looks like this:

```shell
#other options
OPTIONS= -f 1 -x -p -b
```

Don't use -g / -m in the OPTIONS line, use the GAIN / SAMPLE_RATE lines for those settings and only provide the number.

```shell
#gain is 0 to 21, each step of gain is equivalent to about 3dB, so reduce in increments of 1 if 21 is too high
GAIN=21

SAMPLE_RATE=12
# sample rate can be 12 or 20, 20 may not work depending on the system
# when using the Airspy Mini a sample rate of 20 MSPS is not officially supported and an extra heat sink attached to the metal case or active ventilation are recommended
```

Ctrl-O and Enter/Return to save and Ctrl-X to exit

Restart airspy_adsb with:

```shell
sudo systemctl restart airspy_adsb
```

Some more options are discussed on the flightaware forums:
https://discussions.flightaware.com/t/howto-airspy-mini-and-airspy-r2-piaware-dump1090-fa-configuration/44343

If you have questions it is best to just post in that thread!

## Choosing the proper gain:

- In RMS mode (the default), start with the minimum gain and keep increasing and stop just before the strongest AC hit 0 dBFS or you no longer see AC near the -45 dBFS zone.
- In SNR mode, start with the minimum gain and keep increasing until the SNR (displayed as RSSI) no longer improves, then, step it back.

## Show the log, please show that in case of issues:
```shell
# last 60 lines:
sudo journalctl -u airspy_adsb | tail -n60
# scroll the last 2000 lines
sudo journalctl -u airspy_adsb -e -n2000
# update the log live (interrupt with Ctrl-C)
sudo journalctl -u airspy_adsb -ef
```

## Uninstall

Disables the airspy_adsb service, restores the readsb / dump1090-fa configuration and resets the piaware configuration to the default:

```shell
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/uninstall.sh)"
```

---

## Other feeders

It should work fine with all the common feeders (fr24, planefinder, ...).
Just point them to port 30005 (beast protocol).


----

# Helper scripts for recording samples / testing settings

### Install / update the helper scripts:
```
wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/clone-airspy-conf.sh | sudo bash
```

### Record a sample:
Caution: this script was changed to seconds instead of filesize, if you have an old version update first.

```
sudo /usr/local/share/airspy-conf/airspy_record_sample.sh <sample_rate MHz> <gain> <seconds> <bias>
# example command for 12 MHz, gain of 17 and a file size of 15 seconds (automatically capped by the amount of memory you have free)
sudo /usr/local/share/airspy-conf/airspy_record_sample.sh 12 17 15
# with bias-tee enabled:
sudo /usr/local/share/airspy-conf/airspy_record_sample.sh 12 17 15 bias
```

This will use RAM / memory until you remove it or reboot the system.
Removing it:
```
sudo rm /media/airspy_sample/sample.bin
```

### Check -B bandwidth setting:
This setting no longer has any effect.
