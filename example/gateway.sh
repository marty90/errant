#!/bin/bash

# Normally already set to 1 but better be sure for the futur
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ]; then
	echo 1 > /proc/sys/net/ipv4/ip_forward
fi

# Outside
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

if [ -n "$TECHNOLOGY" ]; then
	OPERATOR=${OPERATOR:-"universal"}
	COUNTRY=${COUNTRY:-"universal"}
	QUALITY=${QUALITY:-"universal"}
	/errant -o $OPERATOR -c $COUNTRY -t $TECHNOLOGY -q $QUALITY -i eth0
else
	DOWNLOAD=${DOWNLOAD:-$UPLOAD}
	UPLOAD="$UPLOAD"000
	DOWNLOAD="$DOWNLOAD"000
	/errant -u $UPLOAD -d $DOWNLOAD -R $RTT -L $LOSS -i eth0
fi

sleep infinity