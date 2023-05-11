#!/bin/bash

ASSETS=$(pwd)/assets
SCRIPTS=$(pwd)/scripts
PATH_TO_QEMU=$(pwd)/../qemu-6.2.0/build/qemu-system-x86_64

#${SCRIPTS}/add-tap.sh

sudo bash -c "sleep 3 && ${SCRIPTS}/pin-vm.sh" &
cpu_nr=$2
#swiotlb_opt=$1
enable_sev=$1
mode=$3

PATH_TO_KERNEL=$ASSETS/vanilla-bzImage
[[ $mode == "vanilla" ]] && PATH_TO_KERNEL=$ASSETS/vanilla-bzImage
[[ $mode == "numatx"   ]] && PATH_TO_KERNEL=$ASSETS/zcionuma-bzImage
[[ $mode == "vg"   ]] && PATH_TO_KERNEL=$ASSETS/prpr-bzImage
[[ $mode == "ng"   ]] && PATH_TO_KERNEL=$ASSETS/bifrost-bzImage
[[ $mode == "ngnp"   ]] && PATH_TO_KERNEL=$ASSETS/noprot-bzImage
[[ $mode == "bd"   ]] && PATH_TO_KERNEL=$ASSETS/vanilla-breakdown-bzImage
[[ $mode == "nbd"   ]] && PATH_TO_KERNEL=$ASSETS/zcionuma-breakdown-bzImage
[[ $mode == "vgbd"   ]] && PATH_TO_KERNEL=$ASSETS/prpr-breakdown-bzImage
[[ $mode == "ngbd"   ]] && PATH_TO_KERNEL=$ASSETS/bifrost-breakdown-bzImage

PATH_TO_VMDISK=$ASSETS/focal.img

if [[ $enable_sev == '0' ]]; then
    echo "vanilla"
    swiotlb_opt="swiotlb=noforce"
    ./scripts/add-vmexit-latency.sh 0
elif [[ $enable_sev == '1' ]]; then
    echo "swiotlb"
    swiotlb_opt="swiotlb=524288,force"
    ./scripts/add-vmexit-latency.sh 10500
fi

NUMA_ID=0
echo ${PATH_TO_KERNEL}
sudo numactl --cpubind=${NUMA_ID} --membind=${NUMA_ID} \
${PATH_TO_QEMU} \
    -snapshot \
	-name vm,debug-threads=on \
    -pidfile /tmp/ldj-cvm.pid \
    -serial tcp:localhost:44320 \
	-cpu host \
	--enable-kvm \
	-smp ${cpu_nr} \
    -m 16g \
	-nographic \
    -append "console=ttyS0 nokaslr ignore_loglevel root=/dev/vda1 tsc=reliable zcionuma=1G@8G ${swiotlb_opt} " \
	-kernel ${PATH_TO_KERNEL} \
    -object memory-backend-file,id=ram-node0,mem-path=/dev/hugepages,share=on,size=16G,host-nodes=$NUMA_ID,policy=bind \
    -numa node,nodeid=0,cpus=0-$(($cpu_nr - 1)),memdev=ram-node0 \
	-initrd ${ASSETS}/initramfs.cpio.gz \
	-device virtio-blk-pci,drive=vdisk,disable-modern=on \
    -drive if=none,id=vdisk,format=qcow2,file=$PATH_TO_VMDISK \
    -chardev socket,id=charnet0,path=/tmp/vhostuser1.sock,server=on \
    -netdev vhost-user,chardev=charnet0,id=hostnet0,queues=2 \
    -device virtio-net-pci,netdev=hostnet0,id=vnet0,mac=52:54:00:be:51:5a,vectors=6,mq=on,iommu_platform=on,disable-legacy=on,csum=on,guest_csum=on,guest_tso4=on,guest_tso6=on
