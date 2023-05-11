#!/usr/bin/gnuplot
reset
set output "../../../../figures/fig-07-b.eps"
set terminal postscript "Helvetica" eps enhance dl 2 color size 4,1.5
set pointsize 1

# margin
set tmargin 1
set bmargin 5
set lmargin 9

# legend
unset key
set key outside right Left reverse enhanced autotitles columnhead nobox font ",30"
set key above
set key at 1.5,45
set key vertical maxrows 2
set key samplen 0.4 spacing 0.8 height 0.5
unset key

# x-axis
set xlabel font ",34" offset 0,0.5
set xtics font ",29" offset 0,-0.1
#set xtics norangelimit
set label "1vCPU" offset 0,-3 font ",30"
set label "4vCPU" offset 27,-3 font ",30"

# y-axis
# set ylabel "Relative Overhead" offset -5,0 font ",32"
set yrange[0:20]
set ytics 0, 10, 20 font ",28"
set grid ytics lw 2
set format y "%g%%"
set offset -0.4,-0.4,0,0

# histogram
set style histogram cluster gap 1.2 title textcolor lt -1 
set style data histograms
set style fill solid border -1
#set boxwidth 0.75

# redline
set arrow 1 from 1.5,-5 to 1.5,30 nohead lc "red" front
set arrow 1 dt 6

plot newhistogram "",\
     'res/nginx.res'   u 2:xtic(1)  ti col lc rgb '#C6DBEF' lw 4 ,\
     'res/nginx.res'   u 3:xtic(1)  ti col lc rgb '#6BAED6' lw 4, \
     'res/nginx.res'   u 4:xtic(1)  ti col lc rgb '#2171B5' lw 4, \
     'res/nginx.res'   u 5:xtic(1)  ti col lc rgb '#084594' lw 4,\