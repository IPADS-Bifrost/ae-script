#!/bin/bash

cmd=$1

if [[ $cmd == 'clear' ]]; then
    sudo rmmod breakdown
    sudo modprobe breakdown cmd=2
elif [[ $cmd == 'enable' ]]; then
    sudo rmmod breakdown
    sudo modprobe breakdown cmd=0 arg=1
elif [[ $cmd == 'disable' ]]; then
    sudo rmmod breakdown
    sudo modprobe breakdown cmd=0 arg=0
elif [[ $cmd == 'show' ]]; then
    sudo rmmod breakdown
    sudo modprobe breakdown cmd=3
    dmesg
fi
