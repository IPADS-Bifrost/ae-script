# Gnuplot Script

You can run `./draw.sh` to generate output in each directory.

## Motivation

* fig:moti-app-overhead-mixed-dpdk: moti/dpdk-app (three scripts)
* fig:moti-memcached-breakdown: moti/breakdown (two scripts)
* fig:moti-vmexit-cost: moti/vmexit-cost (one script)
* fig:moti-vmexit-count: moti/vmexit-times (one script)

## Evaluation
* fig:eval-tls-microbenchmark-optirq: eval/amd/tls (one script)
* fig:eval-tls-microbenchmark-postedirq: eval/intel/tls (one script)
* fig:eval-memtier-optirq: eval/mixed/dpdk-app/memtier\ copy.gp. In eval/mixed/dpdk-app, there are six scripts. Those with "\ copy" are for optirq, otherwise are for postedirq. These scripts corresponds to fig:eval-app-optirq and fig:eval-app-postedirq.
* fig:eval-breakdown-memtier-optirq: eval/amd/breakdown (one script)
* fig:eval-breakdown-memtier-postedirq: eval/intel/breakdown (one script)
* fig:eval-optirq-tocttou: eval/amd/tocttou (three scripts)
* fig:eval-postedirq-tocttou: eval/intel/tocttou (three scripts)
