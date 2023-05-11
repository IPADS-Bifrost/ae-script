#!/bin/bash
mkdir -p res
python3 resgen.py
gnuplot memtier-intel.gp
gnuplot memtier-amd.gp
gnuplot nginx-intel.gp
gnuplot nginx-amd.gp
gnuplot redis-intel.gp
gnuplot redis-amd.gp
