#!/bin/bash

source env.sh
memtier_only=0
run_memtier() {
	raw=memtier.log
	stat=$1
    hit_param=

        [[ $6 != 0 ]] && hit_param=--hit-rate=$6\ --key-maximum=10000
        $MEMTIER_PATH/memtier_benchmark --hide-histogram --tls --tls-skip-verify \
            --cert=$TLS_PATH/redis.crt \
            --key=$TLS_PATH/redis.key \
            --cacert=$TLS_PATH/ca.crt \
            -t $2 -c $3 \
            -s $5 -p 11211 -P memcache_binary \
            --test-time=$MEMTIER_DURATION -d $4 $hit_param | tee $raw
	sed -n '/Totals/p' $raw | awk '{print $2, $5, $6, $7}'>>$stat
	rm $raw
}

clear_memtier() {
    $MEMTIER_PATH/memtier_benchmark --hide-histogram --tls --tls-skip-verify \
    --cert=$TLS_PATH/redis.crt \
            --key=$TLS_PATH/redis.key \
            --cacert=$TLS_PATH/ca.crt \
            -s $5 -p 11211 -P memcache_binary \
            -t 1 -c 1 \
            -d $4 -n allkeys \
    --ratio=1:0 --key-pattern=S:R --key-maximum=10000 --hit-rate=$6

}

run_redis() {
        raw=redis.log
        stat=$1
        port=6379
        hit_param=
        [[ $7 == 4 ]] && port=6380\ --cluster-mode\ --distinct-client-seed\ --randomize

        [[ $6 != 0 ]] && hit_param=--hit-rate=$6\ --key-maximum=10000
        $MEMTIER_PATH/memtier_benchmark --hide-histogram --tls --tls-skip-verify \
        --cert=$TLS_PATH/redis.crt \
        --key=$TLS_PATH/redis.key \
        --cacert=$TLS_PATH/ca.crt \
        -s $5 -p $port \
        -t $2 -c $3 \
        --test-time=$MEMTIER_DURATION -d $4 $hit_param | tee $raw

	sed -n '/Totals/p' $raw | awk '{print $2, $5, $6, $7}'>>$stat
	rm $raw
}
clear_redis() {
        raw=redis.log
        stat=$1
        port=6379
        [[ $7 == 4 ]] && port=6380\ --cluster-mode\ --distinct-client-seed\ --randomize

        $MEMTIER_PATH/memtier_benchmark --hide-histogram --tls --tls-skip-verify \
        --cert=$TLS_PATH/redis.crt \
        --key=$TLS_PATH/redis.key \
        --cacert=$TLS_PATH/ca.crt \
        -s $5 -p $port \
        -t 1 -c 1 -n allkeys -d $4 --hit-rate=$6 --ratio=1:0 --key-pattern=S:R --key-maximum=10000
}

run_wrk() {
	raw=tmp.wrk
        stat=$1

    wrk -t$2 -c$3 -d${MEMTIER_DURATION}s https://$5/$4.bin | tee $raw
    #wrk -t$1 -c$2 -d30s http://$4:80/$3 | tee $raw
	sed -n '/Requests\/sec/p' $raw | awk '{print $2}' >> $stat
	rm $raw
}

set_latency() {
    ssh $SSH_HOST "$BENCH_SCRIPT_PATH/scripts/add-vmexit-latency.sh $1"
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
        [[ $mode == "npg" || $mode == "vpg" || $mode == "vg" || $mode == "ng" || $mode == "ngnp" ]] && gro=1

        memtier_sz=(${MEMTIER_DATA_SZ[*]})
        memtier_sz_num=$MEMTIER_DATA_SZ_NUM
        redis_sz=(${REDIS_DATA_SZ[*]})
        redis_sz_num=$REDIS_DATA_SZ_NUM
        nginx_sz=(${NGINX_DATA_SZ[*]})
        nginx_sz_num=$NGINX_DATA_SZ_NUM

        [[ $eval == 1 ]] && memtier_sz=(${MEMTIER_DATA_EV_SZ[*]})
        [[ $eval == 1 ]] && memtier_sz_num=$MEMTIER_DATA_EV_SZ_NUM
        [[ $eval == 1 ]] && redis_sz=(${REDIS_DATA_EV_SZ[*]})
        [[ $eval == 1 ]] && redis_sz_num=$REDIS_DATA_EV_SZ_NUM
        [[ $eval == 1 ]] && nginx_sz=(${NGINX_DATA_EV_SZ[*]})
        [[ $eval == 1 ]] && nginx_sz_num=$NGINX_DATA_EV_SZ_NUM
        ssh $SSH_HOST "cd $BENCH_SCRIPT_PATH/scripts && ./install.sh $gro"
        ssh $SSH_HOST "cd $BENCH_SCRIPT_PATH/scripts && ./start.sh"


        for (( vm_config = $VM_CONFIG_START; vm_config < $VM_CONFIG_END; vm_config ++ )); do
                cpu_nr=${CPU_NR[$vm_config]}
                threads=${MEMTIER_THREADS[$vm_config]}
                conn=${MEMTIER_CONN[$vm_config]}

                echo "" >> $RUN_LOG
                echo "[$mode][$(date|awk '{print $5}')] start vm (${cpu_nr}vcpu swiotlb:${swiotlb_opt})" >> $RUN_LOG
                
                ssh -fn $SSH_HOST "cd $BENCH_SCRIPT_PATH && bash test.sh  '$swiotlb_opt' '$cpu_nr' '$mode'"

                sleep $WAIT_VM_TIME

                ssh $SSH_VM "sed -i 's|-t .|-t ${cpu_nr}|g' /etc/memcached.conf"
                ssh $SSH_VM "systemctl restart memcached"

                ssh $SSH_VM "systemctl stop systemd-journald"
                [[ ${cpu_nr} == 1 ]] && ssh $SSH_VM "redis-server /etc/redis/redis.conf --io-threads ${cpu_nr}"
		[[ ${cpu_nr} == 4 ]] && ssh $SSH_VM "/root/cluster-redis.sh"
                ssh $SSH_VM "nginx"
                ssh $SSH_VM "netserver -L $VM -4 -p 33333"

                echo "[$mode][$(date|awk '{print $5}')] set memcached to ${cpu_nr} thread" >> $RUN_LOG

                for (( data_idx = 0; data_idx < $memtier_sz_num; data_idx ++ )); do
                        data_sz=${memtier_sz[$data_idx]}
                        output=data/intel-memtier-${mode}-${swiotlb_opt}-${cpu_nr}vcpu-${hit_rate}-${data_sz}.stat
                        echo "[$mode][$(date|awk '{print $5}')] set data size to ${data_sz}B" >> $RUN_LOG
                        [[ $hit_rate != "0" ]] && clear_memtier $output $threads $conn $data_sz $VM $hit_rate
                        run_memtier /dev/null $threads $conn $data_sz $VM $hit_rate
                        for (( i = 0; i < $MEMTIER_TEST_TIMES; i ++  )); do
                                echo "[$mode][$(date|awk '{print $5}')] iter:${i}......" \
                                        "vcpu:${cpu_nr} thread:${threads} connection:${conn} data:${data_sz}" >> $RUN_LOG
                                run_memtier $output $threads $conn $data_sz $VM $hit_rate
                        done
                done
                if [[ $memtier_only == 1 ]]; then
                    ssh $SSH_HOST "cat /tmp/ldj-cvm.pid | xargs kill -09"
                    echo "[$mode][$(date|awk '{print $5}')] shutdown vm">> $RUN_LOG
                    sleep $WAIT_PIDFILE_TIME # wait until vm tmp pid file is clear
                    continue
                fi

                for (( data_idx = 0; data_idx < $redis_sz_num; data_idx ++ )); do
                        data_sz=${redis_sz[$data_idx]}
                        output=data/intel-redis-${mode}-${swiotlb_opt}-${cpu_nr}vcpu-${hit_rate}-${data_sz}.stat
                        echo "[$mode][$(date|awk '{print $5}')] set data size to ${data_sz}B" >> $RUN_LOG
                        [[ $cpu_nr == 4 ]] && ssh $SSH_VM "redis-cli --tls --cert /etc/tls/redis.crt --key /etc/tls/redis.key --cacert /etc/tls/ca.crt --cluster call 127.0.0.1:6380 FLUSHALL"
			[[ $hit_rate != "0" ]] && clear_redis $output $threads $conn $data_sz $VM $hit_rate $cpu_nr
                        #run_redis /dev/null $threads $conn $data_sz $VM $hit_rate $cpu_nr
                        for (( i = 0; i < $REDIS_TEST_TIMES; i ++  )); do
                                echo "[$mode][$(date|awk '{print $5}')] iter:${i}......" \
                                        "vcpu:${cpu_nr} thread:${threads} connection:${conn} data:${data_sz}" >> $RUN_LOG
				run_redis $output $threads $(( $conn / $cpu_nr )) $data_sz $VM $hit_rate $cpu_nr
                        done
                done

                for (( data_idx = 0; data_idx < $nginx_sz_num; data_idx ++ )); do
                        data_sz=${nginx_sz[$data_idx]}
                        output=data/intel-nginx-${mode}-${swiotlb_opt}-${cpu_nr}vcpu-${data_sz}.stat
                        echo "[$mode][$(date|awk '{print $5}')] set data size to ${data_sz}B" >> $RUN_LOG
                        run_wrk /dev/null $threads $conn $data_sz $VM
                        for (( i = 0; i < $MEMTIER_TEST_TIMES; i ++  )); do
                                echo "[$mode][$(date|awk '{print $5}')] iter:${i}......" \
                                        "vcpu:${cpu_nr} thread:${threads} connection:${conn} data:${data_sz}" >> $RUN_LOG
				run_wrk $output $threads $conn $data_sz $VM
                        done
                done

                if [[ $cpu_nr != 1 ]]; then
                        ssh $SSH_HOST "cat /tmp/ldj-cvm.pid | xargs kill -09"
                        echo "[$mode][$(date|awk '{print $5}')] shutdown vm">> $RUN_LOG
                        sleep $WAIT_PIDFILE_TIME # wait until vm tmp pid file is clear
                        continue
                fi
                p1=2222
                p2=3333
                p3=4444
                p4=5555
                # Microbenchmark TX
                for (( i = 0; i < $TLS_TEST_TIMES; i ++ )); do
                        
                        pkill tls_server
                        stat=data/intel-tls-tx-${mode}-${swiotlb_opt}.stat
                        rm -f tls-*.log
                        pushd $TLS_MICRO_PATH
                        ./tls_server -T -k all -p $p1 | tee tls-$p1.log &
                        ./tls_server -T -k all -p $p2 | tee tls-$p2.log &
                        ./tls_server -T -k all -p $p3 | tee tls-$p3.log &
                        ./tls_server -T -k all -p $p4 | tee tls-$p4.log &
                        popd
                        ssh $SSH_VM "./tls_client_13 -T -k all -g $((8<<30)) -s $CLIENT -p $p1 & \
                                     ./tls_client_13 -T -k all -g $((8<<30)) -s $CLIENT -p $p2 & \
                                     ./tls_client_13 -T -k all -g $((8<<30)) -s $CLIENT -p $p3 & \
                                     ./tls_client_13 -T -k all -g $((8<<30)) -s $CLIENT -p $p4 & \
                                    "
                        mv $TLS_MICRO_PATH/tls-*.log .

                        sleep 3
                        sed -n '/throughput/p' tls-$p1.log | awk '{print $2}' >> $stat
                        sed -n '/throughput/p' tls-$p2.log | awk '{print $2}' >> $stat
                        sed -n '/throughput/p' tls-$p3.log | awk '{print $2}' >> $stat
                        sed -n '/throughput/p' tls-$p4.log | awk '{print $2}' >> $stat
                        rm -f tls-*.log

                        pkill tls_server
                done

                # Microbenchmark RX
                for (( i = 0; i < $TLS_TEST_TIMES; i ++ )); do
                        ssh $SSH_VM "pkill tls_server"
                        stat=data/intel-tls-rx-${mode}-${swiotlb_opt}.stat

                        ssh $SSH_VM "rm -f /tmp/tls-*.log"
                        ssh -fn $SSH_VM "./tls_server -T -k all -p $p1 | tee /tmp/tls-$p1.log"
                        ssh -fn $SSH_VM "./tls_server -T -k all -p $p2 | tee /tmp/tls-$p2.log"
                        ssh -fn $SSH_VM "./tls_server -T -k all -p $p3 | tee /tmp/tls-$p3.log"
                        ssh -fn $SSH_VM "./tls_server -T -k all -p $p4 | tee /tmp/tls-$p4.log"

                        sleep 3

                        pushd $TLS_MICRO_PATH
                        ./tls_client_13 -T -k all -g $((8<<30)) -s $VM -p $p1 & \
                        ./tls_client_13 -T -k all -g $((8<<30)) -s $VM -p $p2 & \
                        ./tls_client_13 -T -k all -g $((8<<30)) -s $VM -p $p3 & \
                        ./tls_client_13 -T -k all -g $((8<<30)) -s $VM -p $p4
                        popd
                        sleep 2

                        scp "$SSH_VM:/tmp/tls-*.log" .
                        
                        sed -n '/throughput/p' tls-$p1.log | awk '{print $2}' >> $stat
                        sed -n '/throughput/p' tls-$p2.log | awk '{print $2}' >> $stat
                        sed -n '/throughput/p' tls-$p3.log | awk '{print $2}' >> $stat
                        sed -n '/throughput/p' tls-$p4.log | awk '{print $2}' >> $stat
                        rm -f tls-*.log

                        ssh $SSH_VM "pkill tls_server"
                done

                ssh $SSH_HOST "cat /tmp/ldj-cvm.pid | xargs kill -09"
                echo "[$mode][$(date|awk '{print $5}')] shutdown vm">> $RUN_LOG
                sleep $WAIT_PIDFILE_TIME # wait until vm tmp pid file is clear
        done

}

main() {
        [[ -f $RUN_LOG ]] && rm $RUN_LOG
        mkdir -p data
        rm data/*.stat
	ulimit -n 2048

        test vanilla 0 0.1 0
        test vanilla 1 0.1 0
        test numatx 1 0.1 1
        test vg 1 0.1 1
        test ng 1 0.1 1
        test ngnp 1 0.1 1
}

main $@
