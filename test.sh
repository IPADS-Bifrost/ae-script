#!/bin/bash

# qemu line parameter example 
# https://blog.katastros.com/a?ID=01700-b8d7b378-7800-4354-8201-6743cfa32f85

assets=$(pwd)/assets
scripts=$(pwd)/scripts
path_to_kernel=$(pwd)/../cvm-opt-guest/arch/x86/boot/bzImage
path_to_initramfs=$assets/initramfs.cpio.gz
path_to_vdisk=$assets/focal.img
path_to_qemu=$(pwd)/../qemu-6.2.0/build/qemu-system-x86_64

#UEFI_CODE=/usr/share/OVMF/OVMF_CODE.fd

USE_DPDK=1

$scripts/add-tap.sh

sudo iptables -P FORWARD ACCEPT

enable_sev=$1
sev_line=
swiotlb_opt='swiotlb=noforce'
[[ $enable_sev != '0' ]] && sev_line=",confidential-guest-support=lsec0"
[[ $enable_sev != '0' ]] && swiotlb_opt="swiotlb=force"
CPU_MODEL=host

UEFI_CODE=$(pwd)/OVMF_CODE.fd
SEV_GUEST_VARS=$(pwd)/sev-guest_VARS.fd

if [[ $enable_sev == '0' ]]; then
	echo "vanilla"
	sev_guest=sev-guest,id=lsec0,reduced-phys-bits=1,cbitpos=51,policy=0x03
elif [[ $enable_sev == '1' ]]; then
	echo "sev"
	sev_guest=sev-guest,id=lsec0,reduced-phys-bits=1,cbitpos=51,policy=0x03
elif [[ $enable_sev == '2' ]]; then
	echo "sev-es"
	sev_guest=sev-guest,id=lsec0,reduced-phys-bits=1,cbitpos=51,policy=0x06
fi

cpu_nr=$2
mode=$3
[[ $mode == 'vanilla' ]] && path_to_kernel=$assets/vanilla-bzImage
[[ $mode == 'bd' ]] && path_to_kernel=$assets/vanilla-breakdown-bzImage
[[ $mode == 'vobd' ]] && path_to_kernel=$assets/vanilla-breakdown-bzImage
[[ $mode == 'vg' ]] && path_to_kernel=$assets/prpr-bzImage
[[ $mode == 'ng' ]] && path_to_kernel=$assets/bifrost-bzImage
[[ $mode == 'vo' ]] && path_to_kernel=$assets/vanilla-bzImage
[[ $mode == 'no' ]] && path_to_kernel=$assets/zcionuma-bzImage
[[ $mode == 'vgo' ]] && path_to_kernel=$assets/prpr-bzImage
[[ $mode == 'ngo' ]] && path_to_kernel=$assets/bifrost-bzImage
[[ $mode == 'ngnp' ]] && path_to_kernel=$assets/noprot-bzImage
[[ $mode == 'ngonp' ]] && path_to_kernel=$assets/noprot-bzImage
[[ $mode == 'nbd' ]] && path_to_kernel=$assets/zcionuma-breakdown-bzImage
[[ $mode == 'vgbd' ]] && path_to_kernel=$assets/prpr-breakdown-bzImage
[[ $mode == 'ngbd' ]] && path_to_kernel=$assets/bifrost-breakdown-bzImage
[[ $mode == 'nobd' ]] && path_to_kernel=$assets/zcionuma-breakdown-bzImage
[[ $mode == 'vgobd' ]] && path_to_kernel=$assets/prpr-breakdown-bzImage
[[ $mode == 'ngobd' ]] && path_to_kernel=$assets/bifrost-breakdown-bzImage

echo $1 $2 $3
echo $path_to_kernel
sudo bash -c "sleep 5 && ${scripts}/pin-vm.sh" &
NUMA_ID=1
sudo numactl --cpubind=$NUMA_ID --membind=$NUMA_ID \
taskset -c 80-87 $path_to_qemu \
-snapshot \
-name guest=sev-guest,debug-threads=on \
-pidfile /tmp/tyf-cvm.pid \
-serial tcp:localhost:44320 \
-drive if=pflash,format=raw,unit=0,file=$UEFI_CODE,readonly=on \
-blockdev '{"driver":"file","filename":"./sev-guest_VARS.fd","node-name":"libvirt-pflash1-storage","auto-read-only":true,"discard":"unmap"}' \
-blockdev '{"node-name":"libvirt-pflash1-format","read-only":false,"driver":"raw","file":"libvirt-pflash1-storage"}' \
-machine q35,pflash1=libvirt-pflash1-format$sev_line,vmport=off \
-object memory-backend-file,id=ram-node0,mem-path=/dev/hugepages,share=on,size=16G,host-nodes=$NUMA_ID,policy=bind \
-numa node,nodeid=0,cpus=0-$(($cpu_nr - 1)),memdev=ram-node0 \
-accel kvm \
-cpu $CPU_MODEL \
-m 16g \
-smp $cpu_nr \
-nographic \
-boot strict=on \
-device pcie-root-port,id=root.2,chassis=2 \
-kernel $path_to_kernel \
-initrd $path_to_initramfs \
-append "console=ttyS0 nokaslr ignore_loglevel root=/dev/vda1 tsc=reliable zcionuma=1G@8G $swiotlb_opt" \
-device virtio-blk-pci,drive=vdisk \
-drive if=none,id=vdisk,format=qcow2,file=$path_to_vdisk \
-object $sev_guest \
-gdb tcp::1234 \
-chardev socket,id=charnet0,path=/tmp/vhostuser0.sock,server=on \
-netdev vhost-user,chardev=charnet0,id=hostnet0,queues=2 \
-device virtio-net-pci,netdev=hostnet0,id=vnet0,mac=52:54:00:be:51:5a,bus=root.2,vectors=6,mq=on,iommu_platform=on,csum=on,guest_csum=on,guest_tso4=on,guest_tso6=on \
