#!/bin/bash

set -e

echo "clearing old cvm-opt log"

#./log-clear.sh

echo "killing old ovs process"

#pkill -f ovs-vswitchd || true
#sleep 5
#pkill -f ovsdb-server || true
/usr/local/share/openvswitch/scripts/ovs-ctl stop

echo "probing ovs kernel module"

modprobe -r openvswitch || true
modprobe openvswitch

echo "clean env"

DB_FILE=/usr/local/etc/openvswitch/conf.db
rm -rf /usr/local/var/run/openvswitch
mkdir /usr/local/var/run/openvswitch
rm -f $DB_FILE

echo "init ovs db and boot db server"

export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
ovsdb-tool create $DB_FILE /usr/local/share/openvswitch/vswitch.ovsschema
ovsdb-server --remote=punix:$DB_SOCK \
	--remote=db:Open_vSwitch,Open_vSwitch,manager_options \
	--pidfile --detach --log-file
ovs-vsctl --no-wait init

echo "start ovs vswitch daemon"

ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
#ovs-vsctl --no-wait set Open_vSwitch . \
#    other_config:dpdk-extra="--log-level=err --log-file "
    #other_config:dpdk-extra="-d $DPDK_DRIVERS --log-level=err --syslog local0"
ovs-vsctl --no-wait set Open_vSwitch . \
	other_config:dpdk-socket-mem="1024,1024"
#ovs-vsctl --no-wait set Open_vSwitch . \
#	other_config:dpdk-lcore-mask="0x4"
ovs-vsctl --no-wait set Open_vSwitch . \
	other_config:vhost-iommu-support=true
ovs-vsctl --no-wait set Open_vSwitch . other_config:userspace-tso-enable=true
ovs-vswitchd unix:$DB_SOCK --pidfile --detach \
	--log-file=/home/ldj/ovs-dpdk/ovs-vswitchd.log
	#--log-file=/var/log/openvswitch/ovs-vswitchd.log

echo "creating bridge and ports"

ovs-vsctl --if-exists del-br ovsbr1
ovs-vsctl add-br ovsbr1 -- set bridge ovsbr1 datapath_type=netdev
ovs-vsctl add-port ovsbr1 dpdk0 -- \
	set Interface dpdk0 type=dpdk options:dpdk-devargs=0000:98:00.1
ovs-vsctl add-port ovsbr1 vhost-user0 -- \
	set Interface vhost-user0 type=dpdkvhostuserclient \
	options:vhost-server-path=/tmp/vhostuser0.sock
ovs-vsctl add-port ovsbr1 vhost-user1 -- \
	set Interface vhost-user1 type=dpdkvhostuserclient \
	options:vhost-server-path=/tmp/vhostuser1.sock
#ovs-ofctl del-flows ovsbr1
#ovs-ofctl add-flow ovsbr1 "in_port=1,idle_timeout=0 actions=output:2"
#ovs-ofctl add-flow ovsbr1 "in_port=2,idle_timeout=0 actions=output:1"

ovs-vsctl set Open_vSwitch . other_config={}
ovs-vsctl set Open_vSwitch . other_config:dpdk-lcore-mask=0x300000
#ovs-vsctl set Open_vSwitch . other_config:dpdk-lcore-mask=0x200000
#ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0x300000
#ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0x200000
#ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0xf0000000000000000000000
#ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0x30000000000000000000000
#ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=0x2000000000000000000000
PMD_CPU=14
PMD_CPU_MASK=$( printf "0x%X\n" $((5 << $(($PMD_CPU)))))
echo "pmd-cpu-mask $PMD_CPU_MASK"
ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$PMD_CPU_MASK
ovs-vsctl set Interface dpdk0 options:n_rxq=2 \
#    other_config:pmd-rxq-affinity="0:88,1:89" \
#    other_config:pmd-auto-lb="true"
echo "all done"
