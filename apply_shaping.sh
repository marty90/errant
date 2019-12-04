#!/bin/bash

# Default values
PROFILE_FILE="profiles.csv"
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
OPERATOR=""
COUNTRY=""
TECHNOLOGY=""
QUALITY=""
INTERFACE=""

while getopts  "o:c:t:q:i:rhd" flag
do
    case $flag in
        o) OPERATOR=$OPTARG;;
        c) COUNTRY=$OPTARG;;
        t) TECHNOLOGY=$OPTARG;;
        q) QUALITY=$OPTARG;;
        i) INTERFACE=$OPTARG;;
        r) REMOVE=true;;
        d) DRY_RUN=true;;
        h) echo "Usage: apply_shaping.sh -o operator -c country -t technology -q quality -i interface [-r] [-d] [-h]" ; exit ;;
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
        
        # Search for profile
        search=$( cat $PROFILE_FILE |  tail -n +2 | \
                  awk -F , "(\$1==\"$OPERATOR\") && (\$2==\"$COUNTRY\") \
                         && (\$3==\"$TECHNOLOGY\") && (\$4==\"$QUALITY\")" )
        
        if [ -z "$search" ] ; then
            echo "Cannot find selected profile"
        else
        
            # Print infos
            echo "Imposing profile:"
            echo "    Operator:   $OPERATOR"
            echo "    Country:    $COUNTRY"
            echo "    Technology: $TECHNOLOGY"
            echo "    Quality:    $QUALITY"
            
            DOWNLOAD=$(echo $search | cut -d , -f 5)
            UPLOAD=$(echo $search | cut -d , -f 6)
            RTT_AVG=$(echo $search | cut -d , -f 7)
            RTT_SDEV=$(echo $search | cut -d , -f 8)
            
            echo "Parameters are:"
            echo "    Download [kbps]: $DOWNLOAD"
            echo "    Upload [kbps]:   $UPLOAD"
            echo "    RTT [ms]:        $RTT_AVG +- $RTT_SDEV"
            
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
            go tc qdisc add dev $INTERFACE parent 1:11 handle 10: netem delay ${RTT_AVG}ms ${RTT_SDEV}ms distribution normal 
            
        fi                    
        
        
    fi
fi




exit


if [ "$REMOVE" = true ]; then
    # Remove old shaping rules
    echo "Removing all traffic shaping"

    # Remove module IFB
    go rmmod ifb 2>/dev/null

    # Remove all TC policies
    for INTERFACE in $( ifconfig | grep HWaddr | grep -v ifb | cut -d " " -f 1 ) ; do

        go tc qdisc del root dev $INTERFACE 2>/dev/null
        go tc qdisc del dev $INTERFACE handle ffff: ingress 2>/dev/null

    done

else
    # Create rules
    NB_RULES=$( echo $RULES | wc -w)
    echo "Setting shaping on $NB_RULES interfaces"

    #Create virtual interfaces
    go rmmod ifb 2>/dev/null
    go modprobe ifb numifbs=$NB_RULES

    i=0
    for RULE in $RULES ; do

        # Get values
        INTERFACE=$(echo $RULE | cut -d : -f 1)
        DOWNLOAD=$(echo $RULE | cut -d : -f 2)
        UPLOAD=$(echo $RULE | cut -d : -f 3)
        RTT=$(echo $RULE | cut -d : -f 4)
        LOSS=$(echo $RULE | cut -d : -f 5)

        if [ -z "$DOWNLOAD" ]; then DOWNLOAD=$DEFAULT_DOWNLOAD ; fi
        if [ -z "$UPLOAD" ]; then UPLOAD=$DEFAULT_UPLOAD ; fi
        if [ -z "$RTT" ]; then RTT=$DEFAULT_RTT ; fi
        if [ -z "$LOSS" ]; then LOSS=$DEFAULT_LOSS ; fi

        echo "Interface $INTERFACE:"
        echo "    Download: $DOWNLOAD"
        echo "    Upload:   $UPLOAD"
        echo "    RTT:      $RTT"
        echo "    Loss:     $LOSS"

        # Determine virtual interface and set it up
        VIRTUAL=ifb${i}
        ip link set dev $VIRTUAL up

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
        go tc class add dev $VIRTUAL parent 2:1 classid 2:10 htb rate $DOWNLOAD
        # Loss rate 
        go tc qdisc add dev $VIRTUAL parent 2:10  handle 20: netem loss $LOSS


        # OUTGOING
        # Speed
        go tc qdisc add dev $INTERFACE root handle 1: htb default 11
        go tc class add dev $INTERFACE parent 1:  classid 1:1  htb rate $DEFAULT_UPLOAD
        go tc class add dev $INTERFACE parent 1:1 classid 1:11 htb rate $UPLOAD
        # Delay
        go tc qdisc add dev $INTERFACE parent 1:11 handle 10: netem delay $RTT loss $LOSS
        # Loss

        # Increment Counter
        i=$(( $i + 1 ))

    done


fi

