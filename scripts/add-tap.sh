#!/bin/bash
#sudo ip link add br0 type bridge
#sudo ip addr flush dev eno3
#sudo ip link set eno3 master br0

i=-tyf
    sudo ip link del tap$i;
    #sudo ip tuntap add tap$i mode tap user $(whoami) &&
    sudo ip tuntap add tap$i mode tap vnet_hdr multi_queue user $(whoami) &&
        sudo ip link set tap$i master vf-br0 &&
        sudo ip link set dev tap$i up;
