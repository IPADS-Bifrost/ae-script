#!/usr/bin/gnuplot
reset
set output "../../../../figures/fig-11-b.eps"
set terminal postscript "Helvetica" eps enhance dl 2 color size 4,3
set pointsize 1

# margin
set tmargin 6
set bmargin 11
# set lmargin 11

# legend
unset key
set key outside right Left reverse enhanced autotitles columnhead nobox font ",30"
set key above
set key at 1.5,45
set key vertical maxrows 1
set key samplen 0.4 spacing 0.8 height 0.5
unset key

set offset -0.4,-0.4,0,0

#set ylabel "Relative Overhead" offset -2.4,0 font ",24"
set xlabel font ",34" offset 0,0.5
set label "1vCPU" offset 1,-9 font ",50"
set label "4vCPU" offset 25,-9 font ",50"
set yrange[0:2]
set ytics format " "
set ytics 0,0.5,2 font ",26"
set grid ytics lw 2
set xtics font ",40" offset 6,-4.5
set xtics rotate by -25 right

set style histogram cluster gap 1.2 title textcolor lt -1 
set style data histograms
set style fill solid border -1
#set boxwidth 0.75
set arrow 1 from 1.5,-1 to 1.5,5.5 nohead lc "red" front
set arrow 1 dt 6 lw 3

plot newhistogram "",\
     'res/nginx.res'   u 2:xtic(1)   lc rgb '#C6DBEF' lw 4 ,\