#!/bin/bash

gro=0
optirq=0
[ $1 == "1" ] && gro=1
echo gro $gro optirq $optirq

dpdk_path=$(pwd)/../../cvm-opt-dpdk
ovs_path=$(pwd)/../../cvm-opt-ovs
if [[ $gro == 1 ]]; then
    dpdk_commit=prpr
    ovs_commit=prpr
else
    dpdk_commit=0377bb5e636129b0274715808e09e3dc1f37d2d7
    ovs_commit=d8b35c6a83c1453c5fe5db6ea83614a3df25bd82
fi

cd $dpdk_path && git checkout $dpdk_commit && meson build
sudo ninja -C build install
cd $ovs_path && git checkout $ovs_commit
./boot.sh
mkdir -p build && cd build && ../configure --with-dpdk=shared CFLAGS="-g -O2 -march=native -DCVM_OPT" && sudo make install -j$(nproc)
