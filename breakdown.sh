#!/bin/bash

source env.sh
memtier_only=0
run_memtier() {
	raw=memtier.log
	stat=$1
    hit_param=

        [[ $6 != 0 ]] && hit_param=--hit-rate=$6\ --key-maximum=10000
        $MEMTIER_PATH/memtier_benchmark/memtier_benchmark --hide-histogram --tls --tls-skip-verify \
            --cert=$TLS_PATH/redis.crt \
            --key=$TLS_PATH/redis.key \
            --cacert=$TLS_PATH/ca.crt \
            -t $2 -c $3 \
            -s $5 -p 11211 -P memcache_binary \
            --test-time=$MEMTIER_DURATION -d $4 $hit_param | tee $raw
	sed -n '/Totals/p' $raw | awk '{print $2, $5, $6, $7}'>>$stat
	rm $raw
}

run_memtier_breakdown() {
	raw=memtier.log
	stat=$1
        hit_param=

        ssh -fn $SSH_VM "cd /root && cp breakdown.ko.$7 breakdown.ko"

        sleep 5 && ssh -fn $SSH_HOST "cd $BENCH_SCRIPT_PATH  && ./scripts/breakdown.sh clear && ./scripts/breakdown.sh enable" &
        sleep 25 && ssh -fn $SSH_HOST "cd $BENCH_SCRIPT_PATH  && dmesg -c > /dev/null && ./scripts/breakdown.sh show" | tee $raw.host &
        sleep 5 && ssh -fn $SSH_VM "cd /root  && ./breakdown.sh clear && ./breakdown.sh enable" &
        sleep 25 && ssh -fn $SSH_VM "cd /root  && dmesg -c > /dev/null && ./breakdown.sh show" | tee $raw.guest &

        [[ $6 != 0 ]] && hit_param=--hit-rate=$6\ --key-maximum=10000
        $MEMTIER_PATH/memtier_benchmark/memtier_benchmark --hide-histogram --tls --tls-skip-verify \
            --cert=$TLS_PATH/redis.crt \
            --key=$TLS_PATH/redis.key \
            --cacert=$TLS_PATH/ca.crt \
            -s $5 -p 11211 -P memcache_binary \
            -t $2 -c $3 \
            --test-time=$MEMTIER_DURATION -d $4 $hit_param

        echo Total >> $stat-guest.stat
        sed -n '/Total/p' $raw.guest | awk '{print $4}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        echo netrx >> $stat-guest.stat
        sed -n '/netrx/p' $raw.guest | awk '{print $7, $9}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        echo tcp_send >> $stat-guest.stat
        sed -n '/tcp_send/p' $raw.guest | awk '{print $7, $9}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        echo swiotlb_tx >> $stat-guest.stat
        sed -n '/swiotlb_tx/p' $raw.guest | awk '{print $7, $9}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        echo swiotlb_rx >> $stat-guest.stat
        sed -n '/swiotlb_rx/p' $raw.guest | awk '{print $7, $9}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        echo swiotlb_memcpy >> $stat-guest.stat
        sed -n '/swiotlb_memcpy/p' $raw.guest | awk '{print $7, $9}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        echo swiotlb_find >> $stat-guest.stat
        sed -n '/swiotlb_find/p' $raw.guest | awk '{print $7, $9}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        echo swiotlb_release >> $stat-guest.stat
        sed -n '/swiotlb_release/p' $raw.guest | awk '{print $7, $9}' >> $stat-guest.stat
        echo end >> $stat-guest.stat
        rm $raw.guest

        echo Total >> $stat-host.stat
        sed -n '/Total/p' $raw.host | awk '{print $3}' >> $stat-host.stat
        echo end >> $stat-host.stat
        echo interrupt >> $stat-host.stat
        sed -n '/reason 0x60/p' $raw.host | awk '{print $5, $7, $9}' >> $stat-host.stat
        sed -n '/reason 0x64/p' $raw.host | awk '{print $5, $7, $9}' >> $stat-host.stat
        echo end >> $stat-host.stat
        echo msr >> $stat-host.stat
        sed -n '/reason 0x7c/p' $raw.host | awk '{print $5, $7, $9}' >> $stat-host.stat
        echo end >> $stat-host.stat
        rm $raw.host
}

clear_memtier() {
    $MEMTIER_PATH/memtier_benchmark/memtier_benchmark --hide-histogram --tls --tls-skip-verify \
    --cert=$TLS_PATH/redis.crt \
            --key=$TLS_PATH/redis.key \
            --cacert=$TLS_PATH/ca.crt \
            -s $5 -p 11211 -P memcache_binary \
            -t 1 -c 1 \
            -d $4 -n allkeys \
    --ratio=1:0 --key-pattern=S:R --key-maximum=10000 --hit-rate=$6

}

set_latency() {
    ssh $SSH_HOST "rmmod vmexit_latency"
    ssh $SSH_HOST "modprobe vmexit_latency total_lat=$1"
}

set_vhost_zc() {
    ssh $SSH_HOST "modprobe -r vhost_net"
    ssh $SSH_HOST "modprobe vhost_net experimental_zcopytx=$1"
}

test() {
        mode=$1
        #kernel=""
        swiotlb_opt=$2
        hit_rate=$3
		eval=$4
        gro=0
        optirq=0
        [[ $mode == "npg" || $mode == "vpg" || $mode == "vg" || $mode == "ng" || $mode == "vgo" || $mode == "ngo" || $mode == "ngonp" || $mode == "ngnp" ]] && gro=1
        [[ $mode == "vo" || $mode == "no" || $mode == "vgo" || $mode == "ngo" || $mode == "ngonp" ]] && optirq=1

        [[ $mode == "vgbd" || $mode == "ngbd" || $mode == "vgobd" || $mode == "ngobd" ]] && gro=1
        [[ $mode == "vobd" || $mode == "nobd" || $mode == "vgobd" || $mode == "ngobd" ]] && optirq=1

        ssh $SSH_HOST "cd $BENCH_SCRIPT_PATH/scripts && ./install.sh $gro $optirq"


        for (( vm_config = 1; vm_config < 2; vm_config ++ )); do
                cpu_nr=${CPU_NR[$vm_config]}
                threads=${MEMTIER_THREADS[$vm_config]}
                conn=${MEMTIER_CONN[$vm_config]}

                echo "" >> $RUN_LOG
                echo "[$mode][$(date|awk '{print $5}')] start vm (${cpu_nr}vcpu swiotlb:${swiotlb_opt})" >> $RUN_LOG

                ssh $SSH_HOST "cd $BENCH_SCRIPT_PATH/scripts && ./start.sh"
                ssh -fn $SSH_HOST "cd $BENCH_SCRIPT_PATH && bash test.sh  '$swiotlb_opt' '$cpu_nr' '$mode'"
                sleep $WAIT_VM_TIME
                ssh $SSH_VM "sed -i 's|-t .|-t ${cpu_nr}|g' /etc/memcached.conf"
                ssh $SSH_VM "systemctl restart memcached"
                ssh $SSH_VM "systemctl stop systemd-journald"

                echo "[$mode][$(date|awk '{print $5}')] set memcached to ${cpu_nr} thread" >> $RUN_LOG

                data_sz=262144
                output=data/amd-memtier-${mode}-${swiotlb_opt}-breakdown
                echo "[$mode][$(date|awk '{print $5}')] set data size to ${data_sz}B" >> $RUN_LOG
                [[ $hit_rate != "0" ]] && clear_memtier $output $threads $conn $data_sz $VM $hit_rate
                # run_memtier /dev/null $threads $conn $data_sz $VM $hit_rate
                run_memtier_breakdown $output $threads $conn $data_sz $VM $hit_rate $mode

                #ssh $SSH_HOST "sudo pkill qemu"
                #cat /tmp/tyf-cvm.pid | xargs kill -09
                ssh $SSH_HOST "cat /tmp/tyf-cvm.pid | xargs kill -09"
                echo "[$mode][$(date|awk '{print $5}')] shutdown vm">> $RUN_LOG
                sleep $WAIT_PIDFILE_TIME # wait until vm tmp pid file is clear
        done

}

main() {
        [[ -f $RUN_LOG ]] && rm $RUN_LOG
        mkdir -p data
	ulimit -n 2048

        test bd 0 0.1 0
        test bd 2 0.1 0
        test vobd 0 0.1 1
        test vobd 2 0.1 1
        test nobd 2 0.1 1
        test vgobd 2 0.1 1
        test ngobd 2 0.1 1
}

main $@
