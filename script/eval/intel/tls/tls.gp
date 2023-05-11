#!/usr/bin/gnuplot
reset
set output "../../../../figures/fig-06-b.eps"
set terminal postscript "Helvetica" eps enhance dl 2 color size 4,3
set pointsize 1

# margin
set tmargin 8
set bmargin 6
set lmargin 11

# legend
unset key
set key outside Left reverse enhanced autotitles columnhead nobox font ",30"
set key above
set key at 0.5,2.45
set key vertical maxrows 3
set key samplen 0.4 spacing 1 height 0.5

# x
set xtics font ",26"
set xtics scale 0 offset 0,-0.5
set xtics norangelimit

# y
set yrange[0:1.8]
set ytics 0, 0.2, 2 font ",26"
set grid ytics lw 2 #  ----- y dotline ------
set offset -0.45,-0.45,0,0

# histogram
set style data histogram
set style histogram cluster gap 1.2
set style fill solid border -1
set boxwidth 1.0
C = "#C6DBEF"; Cpp = "#6BAED6"; Java = "#2171B5"; Python = "#084594"
plot 'res/tls.res' using 2:xtic(1) ti col lc rgb C,\
                '' u 3 ti col lc rgb Cpp,\
                '' u 4 ti col lc rgb Java,\
                '' u 5 ti col lc rgb Python