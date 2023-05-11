#!/usr/bin/gnuplot
reset
set output "../../../figures/fig-02-c.eps"
set terminal postscript "Helvetica" eps enhance dl 2 color size 7,2
set pointsize 5

# set tmargin 2.9
# set bmargin 6
# # set lmargin 10
# set lmargin 0
# set rmargin 0.1


set tmargin 2
set bmargin 6.28
set rmargin 27
set lmargin 0

##
# unset key
# set key outside right Left reverse enhanced autotitles columnhead nobox font ",20"
# set key above
# set key at 5.2,50
# set key vertical maxrows 1
# set key samplen 2 spacing 1 height 0.5
# unset key
set key outside reverse Left font ",30"
set key samplen 0.5
set key width -2
# set key outside top invert enhanced autotitles columnhead nobox
# set key samplen 0.5 spacing 1 width 0.5 height 0.2 font ",15"
# set key at 8,60
# set key above
set key at 9,30
# set key vertical maxrows 1
# set key samplen 2 spacing 1 height 0.5
# unset key
##
##

#set ylabel "Relative Overhead" offset -2.4,0 font ",24"
set xlabel font ",22" offset 0,0.5
set label "1vCPU" at 1,-10 font ",36"
set label "4vCPU" at 5,-10 font ",36"


set yrange[0:30]
set format y "%g%%"
set ytics 0, 10, 30 font ",24"
set xtics font ",24" offset -0,-0.5 rotate by -0
#set xtics norangelimit
set offset -0.4,-0.4,0,0

set grid ytics lw 2
#configurations=5


set style histogram cluster gap 1.2 title textcolor lt -1 
set style data histograms
set style fill solid border -1
#set boxwidth 0.75


#One-sided	1.153	2.109	0.886	0.886	0
#			1.0X 	1.83X	0.77X	0.77X
#Two-sided	0.836	1.525	1.653	1.841	0
#			1.0X	1.82X	1.98X	2.20X

# set label "1.00X" font ",22" left   at  -0.33,1.3
# set label "1.83X" font ",22" left   at  -0.17,2.3
# set label "0.77X" font ",22" left   at  -0.01,1.1
# set label "0.77X" font ",22" left   at   0.16,1.1

# set label "1.00X" font ",22" left   at   0.67,1.0
# set label "1.82X" font ",22" left   at   0.83,1.7
# set label "1.98X" font ",22" left   at   1.00,1.8
# set label "2.20X" font ",22" left   at   1.16,2.0


set arrow 1 from 3.5,-15 to 3.5,35 nohead lc "red" front
set arrow 1 dt 6

plot newhistogram "",\
     'res/redis.res'   u 2:xtic(1)  ti col lc rgb '#C6DBEF' lw 4 ,\
     'res/redis.res'   u 3:xtic(1)  ti col lc rgb '#2171B5' lw 4
