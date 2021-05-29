# airspy-conf

On popular request i've written a script that does all the work, so all you need to do is change the gain if you want :)

This script changes the piaware configuration, dump1090-fa / readsb configuration and installs a systemd-service to automatically run airspy_adsb.
I have tested the script locally, it should work. But such things sometimes don't work as intended, keep that in mind.

In case your Airspy was purchased earlier than 2017, you will probably need to update its firmware, see the note in regards to ADS-B on the quick start page: https://airspy.com/quickstart/

dump1090-fa or readsb needs to be installed before you run this script otherwise the script can't change the configuration.
It should work very well for example on a piaware-sd card image :)
A normal Raspbian sd card image also works well.
(On a Raspberry Pi the script will even install dump1090-fa for you if it's not present)

In case you don't want dump1090-fa to be installed/configured, you can download the script, and run it like this:

```shell
sudo bash install.sh only-airspy
```

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

```shell
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/install.sh)"
```

---

## Other feeders

While dump1090-fa can be used for this script and configuration to work, you don't have to install piaware.
It should work fine with all the common feeders (fr24, planefinder, ...).
Just point them to port 30005 (beast protocol).

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

There are other lines where you can change the gain or sample rate:

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

## Uninstall

Disables the airspy_adsb service, restores the readsb / dump1090-fa configuration and resets the piaware configuration to the default:

```shell
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/uninstall.sh)"
```

---

## Update

Update / download airspy_adsb to /usr/local/bin while preserving options in /etc/default/airspy_adsb

```shell
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/update-binary.sh)"
```

---
