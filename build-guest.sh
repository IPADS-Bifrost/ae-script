#!/bin/bash

export BENCH_SCRIPT_PATH=$(pwd)/
export CONFIG_PATH=$(pwd)/config
mkdir -p $BENCH_SCRIPT_PATH
mkdir -p $BENCH_SCRIPT_PATH/assets
mkdir -p $BENCH_SCRIPT_PATH/assets/breakdown

cd ..

cd cvm-opt-guest
git checkout bifrost
git pull

# Build Vanilla kernel
cp $CONFIG_PATH/vanilla-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/vanilla-bzImage

# Build CVM+ZC kernel
cp $CONFIG_PATH/zcionuma-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/zcionuma-bzImage

# Build CVM+PRPR kernel
cp $CONFIG_PATH/prpr-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/prpr-bzImage

# Build Bifrost kernel
cp $CONFIG_PATH/bifrost-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/bifrost-bzImage

# Build Bifrost kernel (without TOCTTOU protection)
git checkout without-tocttou-protection
git pull
cp $CONFIG_PATH/bifrost-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/noprot-bzImage

# Build Vanilla kernel for breakdown
git checkout breakdown
git pull
cp $CONFIG_PATH/vanilla-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/vanilla-breakdown-bzImage
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.bd
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.vobd

# Build CVM+ZC kernel for breakdown
cp $CONFIG_PATH/zcionuma-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/zcionuma-breakdown-bzImage
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.nbd
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.nobd

# Build CVM+PRPR kernel for breakdown
cp $CONFIG_PATH/prpr-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/prpr-breakdown-bzImage
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.vgbd
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.vgobd

# Build Bifrost kernel for breakdown
cp $CONFIG_PATH/bifrost-config .config
make -j$(nproc)
cp ./arch/x86/boot/bzImage $BENCH_SCRIPT_PATH/assets/bifrost-breakdown-bzImage
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.ngbd
cp ./mm/breakdown.ko $BENCH_SCRIPT_PATH/assets/breakdown/breakdown.ko.ngobd

cd $BENCH_SCRIPT_PATH
