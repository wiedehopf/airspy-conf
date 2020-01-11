# airspy-conf

On popular request i've written a script that does all the work, so all you need to do is change the gain if you want :)

This script changes the piaware configuration, dump1090-fa configuration and installs a systemd-service to automatically run airspy_adsb.
I have tested the script locally, it should work. But such things sometimes don't work as intended, keep that in mind.

In case your Airspy was purchased earlier than 2017, you will probably need to update its firmware, see the note in regards to ADS-B on the quick start page: https://airspy.com/quickstart/

dump1090-fa needs to be installed before you run this script otherwise the script can't change the configuration.
It should work very well for example on a piaware-sd card image :)
A normal Raspbian sd card image also works well.
(On a Raspberry Pi the script will even install dump1090-fa for you if it's not present)

If you want to use it with dump1090-fa on another system you will have to install it yourself before running this script.

In case you don't want dump1090-fa to be installed/configured, you can download the script, and run it like this:
```
sudo bash install.sh only-airspy
```

Content:
* [Installation](https://github.com/wiedehopf/airspy-conf#installation)
* [Other feeders](https://github.com/wiedehopf/airspy-conf#other-feeders)
* [Changing airspy options](https://github.com/wiedehopf/airspy-conf#Changing-airspy_adsb-options)
* [Uninstall](https://github.com/wiedehopf/airspy-conf#Uninstall)
* [Update](https://github.com/wiedehopf/airspy-conf#Update)
---

## Installation:

```
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/install.sh)"
```
---
## Other feeders:

While dump1090-fa needs to be installed for this script and configuration to work, you don't have to install piaware.
It should work fine with all the common feeders (fr24, planefinder, ...).
Just point them to port 30005 (beast protocol).

---
## Changing airspy_adsb options

If you want to change the airspy options, edit the option file:

```
sudo nano /etc/default/airspy_adsb
```

For example you might want to enable the bias tee, just add `-b` at the end of the options line so it looks like this:
```
#other options
OPTIONS= -f 1 -x -p -b
```
There are other lines where you can change the gain or sample rate:
```
#gain is 0 to 21, each step of gain is equivalent to about 3dB, so reduce in increments of 1 if 21 is too high
GAIN=21

#sample rate can be 12 or 20, 20 is not recommended on the Raspbery Pi, if you chose it please check for lost samples with journalctl -en100 -u airspy_adsb
SAMPLE_RATE=12
```

Ctrl-O and Enter/Return to save and Ctrl-X to exit

Restart airspy_adsb with
```
sudo systemctl restart airspy_adsb dump1090-fa
```

Some more options are discussed on the flightaware forums:
https://discussions.flightaware.com/t/howto-airspy-mini-and-airspy-r2-piaware-dump1090-fa-configuration/44343

If you have questions it is best to just post in that thread!

## Uninstall:

Disables the airspy_adsb service, restores the dump1090-fa configuration and resets the piaware configuration to the default:
```
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/uninstall.sh)"
```
---

## Update:
Update / download airspy_adsb to /usr/local/bin while preserving options in /etc/default/airspy_adsb

```
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/wiedehopf/airspy-conf/master/update-binary.sh)"
```
----
