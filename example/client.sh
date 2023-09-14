#!/bin/sh

function network_setup {

    GATEWAY=${GATEWAY:-gateway}

    GATEWAY_IP=$(getent hosts $GATEWAY | cut -d" " -f1 | head -n 1)
    ip route delete default
    ip route add default via $GATEWAY_IP dev eth0

}

network_setup

if [ -n "$TECHNOLOGY" ]; then
    OPERATOR=${OPERATOR:-"universal"}
    COUNTRY=${COUNTRY:-"universal"}
    QUALITY=${QUALITY:-"universal"}
    echo "Imposing profile:"
    echo "    Operator:   $OPERATOR"
    echo "    Country:    $COUNTRY"
    echo "    Technology: $TECHNOLOGY"
    echo "    Quality:    $QUALITY"
    
    echo "To see the parameters see the gateway's logs"

else
    DOWNLOAD=${DOWNLOAD:-$UPLOAD}
    UPLOAD="$UPLOAD"000
    DOWNLOAD="$DOWNLOAD"000
    
    echo "Parameters are:"
    echo "    Download [kbps]: $DOWNLOAD"
    echo "    Upload [kbps]:   $UPLOAD"
    echo "    RTT [ms]:        $RTT"
    echo "    LOSS [%]:        $LOSS"
    
fi

echo
echo Measuring Bandwith
# Measure the bandwith
iperf3 -c $SERVER -i 1

echo
echo Measuring Loss
# Measure the loss
iperf3 -c $SERVER -i 1 -u

echo
echo Measuring RTT
# Measure the RTT
ping $SERVER -c 10

