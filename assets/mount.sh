#!/bin/bash

sudo modprobe nbd max_part=2

sudo qemu-nbd -c /dev/nbd0 -f qcow2 ./focal.img

sleep 1

mkdir -p mnt

sudo mount /dev/nbd0p1 ./mnt