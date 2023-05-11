#!/bin/bash

export PAPER=$(pwd)

# figure 2
echo "Drawing Figure-2..."
cd $PAPER/script/moti/dpdk-app/
./draw.sh

# figure 3
echo "Drawing Figure-3..."
cd $PAPER/script/moti/breakdown/
./draw.sh

# figure 6a
echo "Drawing Figure-6a..."
cd $PAPER/script/eval/amd/tls
./draw.sh

# figure 6b
echo "Drawing Figure-6b..."
cd $PAPER/script/eval/intel/tls
./draw.sh

# figure 7&8
echo "Drawing Figure-7&8..."
cd $PAPER/script/eval/mixed/dpdk-app
./draw.sh

# figure 9
echo "Drawing Figure-9..."
cd $PAPER/script/eval/amd/breakdown
./draw.sh

# figure 10
echo "Drawing Figure-10..."
cd $PAPER/script/eval/intel/breakdown
./draw.sh

# figure 11
echo "Drawing Figure-11..."
cd $PAPER/script/eval/amd/tocttou
./draw.sh

# figure 12
echo "Drawing Figure-12..."
cd $PAPER/script/eval/intel/tocttou
./draw.sh
