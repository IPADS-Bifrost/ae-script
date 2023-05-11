#!/bin/bash

for i in $(seq 0 1)
do
    if [ -e /sys/class/net/ens6v$i ]; then
        sudo ip link set ens6 vf $i trust on
        sudo ip link set ens6 vf $i mac 66:11:22:33:4$i:55
        sudo ip link set ens6v$i up
    fi
done

if ! [ -e /sys/class/net/tap0  ]; then
    for i in $(seq 0 0)
    do
        #sudo ip link del tap$i;
        #sudo ip tuntap add tap$i mode tap user $(whoami) &&
            #sudo ip link set tap$i master br0 &&
        sudo ip tuntap add tap$i mode tap vnet_hdr multi_queue user $(whoami) &&
            sudo ip link set tap$i master vbr0 &&
            sudo ip link set dev tap$i up;
    done
fi

if ! [ -e /sys/class/net/eth-tap0  ]; then
    for i in $(seq 0 0)
    do
        #sudo ip link del eth-tap$i;
        #sudo ip tuntap add eth-tap$i mode tap vnet_hdr multi_queue user $(whoami) &&
        sudo ip tuntap add eth-tap$i mode tap user $(whoami) &&
            sudo ip link set eth-tap$i master eth-br0 &&
            sudo ip link set dev eth-tap$i up;
    done
fi

sudo iptables -P FORWARD ACCEPT
