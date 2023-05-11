#!/bin/bash
mkdir -p res
python3 resgen.py
python3 relabel.py
gnuplot 4vcpu-breakdown.gp
