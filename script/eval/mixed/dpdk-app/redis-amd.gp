#!/usr/bin/gnuplot
reset
set output "../../../../figures/fig-07-c.eps"
set terminal postscript "Helvetica" eps enhance dl 2 color size 5,1.5
set pointsize 1

# margin
set tmargin 2
set bmargin 4.7
set lmargin 7

# legend
unset key
set key outside reverse Left font ",30"
set key samplen 0.5
set key width 1
# unset key

# x-axis
set xlabel font ",34" offset 0,0.5
set xtics font ",27" offset 0,-0.1
#set xtics norangelimit
set label "1vCPU" offset 0,-6 font ",28"
set label "4vCPU" offset 26,-6 font ",28"

# y-axis
set yrange[-10:20]
set format y "%g%%"
set ytics -15, 10, 25 font ",26"
set grid ytics lw 2
set offset -0.4,-0.4,0,0
# set ylabel "Relative Overhead" offset -3.6,0 font ",32"

# histogram
set style histogram cluster gap 1.2 title textcolor lt -1 
set style data histograms
set style fill solid border -1
#set boxwidth 0.75

# redline
set arrow 1 from 1.5,-17.5 to 1.5,22 nohead lc "red" front
set arrow 1 dt 6

plot newhistogram "",\
     'res/redis.res'   u 2:xtic(1)  ti col lc rgb '#C6DBEF' lw 4 ,\
     'res/redis.res'   u 3:xtic(1)  ti col lc rgb '#6BAED6' lw 4, \
     'res/redis.res'   u 4:xtic(1)  ti col lc rgb '#2171B5' lw 4, \
     'res/redis.res'   u 5:xtic(1)  ti col lc rgb '#084594' lw 4,\