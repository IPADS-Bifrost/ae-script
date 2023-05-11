#!/bin/bash
mkdir -p res
python3 resgen.py
gnuplot tls.gp
