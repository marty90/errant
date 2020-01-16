#!/bin/bash

# Default values
VIRTUAL=ifb0
DEFAULT_DOWNLOAD="40000mbit"
DEFAULT_UPLOAD="40000mbit"
DEFAULT_RTT="0ms"

# Utility Function
function go() {
    if [ "$DRY_RUN" = true ]; then
        echo "+ $*"
    else
        eval "$*"
    fi
    return $?
}

# Parse Args
DRY_RUN=false
REMOVE=false
PERIODIC=""
OPERATOR=""
COUNTRY=""
TECHNOLOGY=""
QUALITY=""
INTERFACE=""

while getopts  "o:c:t:q:i:p:rhd" flag
do
    case $flag in
        o) OPERATOR=$OPTARG;;
        c) COUNTRY=$OPTARG;;
        t) TECHNOLOGY=$OPTARG;;
        q) QUALITY=$OPTARG;;
        i) INTERFACE=$OPTARG;;
        r) REMOVE=true;;
        d) DRY_RUN=true;;
        p) PERIODIC=$OPTARG;;
        h) echo "Usage: apply_shaping.sh -o operator -c country -t technology -q quality -i interface [-p period] [-r] [-d] [-h]" ; exit ;;
    esac
done


# Remove rules
if [ "$REMOVE" = true ]; then

    # Check arguments are correct
    if [ -z "$OPERATOR" ] && [ -z "$COUNTRY" ] && [ -z "$TECHNOLOGY" ] \
                          && [ -z "$QUALITY" ] && [ -z "$INTERFACE" ]; then
        echo "Removing shaping rules"
        
        # Remove module IFB
        go rmmod ifb 2>/dev/null

        # Remove all TC policies
        for INTERFACE in $( ifconfig | grep HWaddr | grep -v ifb | cut -d " " -f 1 ) ; do

            go tc qdisc del root dev $INTERFACE 2>/dev/null
            go tc qdisc del dev $INTERFACE handle ffff: ingress 2>/dev/null

        done
        
    else
        echo "When removing rules, all other arguemnts must be empty"
    fi
    
else
    if [ -z "$OPERATOR" ] || [ -z "$COUNTRY" ] || [ -z "$TECHNOLOGY" ] \
                          || [ -z "$QUALITY" ] || [ -z "$INTERFACE" ]; then
        echo "You should specify all of operator,country, technology, quality and interface"
    else
        echo "Imposing shaping on interface: $INTERFACE"
        
        if [ ! -z $PERIODIC ] ; then
            if ! [[ "$PERIODIC" =~ ^[0-9]+$ ]] ; then
                echo "Wrong periodic shaping value. Only integers allowed."
                exit
            else
                echo "Periodic shaping with period: $PERIODIC"
            fi
        fi
        
        while true ; do
            # Search for profile
            values=$( python3 sample_from_distribution.py $OPERATOR $COUNTRY $TECHNOLOGY $QUALITY )
                    
            if [ "$values" = "error" ] ; then
                echo "Cannot find selected profile"
                exit
            else
            
                # Print infos
                echo "Imposing profile:"
                echo "    Operator:   $OPERATOR"
                echo "    Country:    $COUNTRY"
                echo "    Technology: $TECHNOLOGY"
                echo "    Quality:    $QUALITY"
                
                DOWNLOAD=$(echo $values | cut -d " " -f 1)
                UPLOAD=$(echo $values | cut -d " " -f 2)
                RTT_AVG=$(echo $values | cut -d " " -f 3)
                
                echo "Parameters are:"
                echo "    Download [kbps]: $DOWNLOAD"
                echo "    Upload [kbps]:   $UPLOAD"
                echo "    RTT [ms]:        $RTT_AVG"
                
                # Impose shaping
                
                # Create virtual interfaces
                go rmmod ifb 2>/dev/null
                go modprobe ifb numifbs=1
                go ip link set dev $VIRTUAL up
                
                # Create rules
                # Clear old
                go tc qdisc del root dev $INTERFACE 2>/dev/null       # clear outgoing
                go tc qdisc del dev $INTERFACE handle ffff: ingress 2>/dev/null    # clear incoming
                go tc qdisc del root dev $VIRTUAL 2>/dev/null


                # Create Device Pipes
                go tc qdisc add dev $INTERFACE handle ffff: ingress
                go tc filter add dev $INTERFACE parent ffff: protocol ip u32 match u32 0 0 \
                                                action mirred egress redirect dev $VIRTUAL


                # INCOMING
                # Speed
                go tc qdisc add dev $VIRTUAL root handle 2: htb default 10
                go tc class add dev $VIRTUAL parent 2:  classid 2:1  htb rate $DEFAULT_DOWNLOAD
                go tc class add dev $VIRTUAL parent 2:1 classid 2:10 htb rate ${DOWNLOAD}kbit


                # OUTGOING
                # Speed
                go tc qdisc add dev $INTERFACE root handle 1: htb default 11
                go tc class add dev $INTERFACE parent 1:  classid 1:1  htb rate $DEFAULT_UPLOAD
                go tc class add dev $INTERFACE parent 1:1 classid 1:11 htb rate ${UPLOAD}kbit
                # Delay
                go tc qdisc add dev $INTERFACE parent 1:11 handle 10: netem delay ${RTT_AVG}ms
                
            fi 
            
            if [ -z $PERIODIC ] ; then
                break
            else
                echo "Sleeping $PERIODIC seconds..."
                sleep $PERIODIC
            fi
                               
        done
        
    fi
fi



