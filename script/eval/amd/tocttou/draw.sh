#!/bin/bash
mkdir -p res
python3 resgen.py
gnuplot memtier.gp
gnuplot nginx.gp
gnuplot redis.gp