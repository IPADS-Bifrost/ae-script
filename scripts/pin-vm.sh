#!/bin/bash

QEMU_PID=$(cat /tmp/tyf-cvm.pid)

NR_VCPU=$(qemu-affinity -v --dry-run -- $QEMU_PID | grep CPU | wc -l)
PLUS=1
START_VCPU=80
END_VCPU=$(($START_VCPU + $NR_VCPU * $PLUS - 1))
#END_VCPU=$(($START_VCPU + $NR_VCPU * 4 - 1))

echo "Try to pin vcpu thread... qemu-system pid:"$qemu_pid
qemu-affinity $QEMU_PID -k $(seq $START_VCPU $PLUS $END_VCPU)
#qemu-affinity $QEMU_PID -k $(seq $START_VCPU 4 $END_VCPU)
qemu-affinity -v --dry-run -- $QEMU_PID

START_VHOST=$(($END_VCPU + 1 ))
#START_VHOST=65

echo "Try to pin vhost thread..."
core0=$START_VHOST
for vhost_pid in $(pgrep vhost-$qemu_pid); do
	taskset -cp $core0 $vhost_pid
	core0=$((core0 + $PLUS))
done

#core0=$START_VHOST
#core1=$(($START_VHOST + 2))
#for vhost_pid in $(pgrep vhost-$qemu_pid); do
#	taskset -cp $core0,$core1 $vhost_pid
#	core0=$((core0 + 4))
#	core1=$((core1 + 4))
#done
