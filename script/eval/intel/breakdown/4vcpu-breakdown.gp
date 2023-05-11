#!/usr/bin/gnuplot
reset
set output "../../../../figures/fig-10.eps"
set terminal postscript "Helvetica,14" eps enhance dl 2 color size 5,1.5

# margin
set bmargin 2
# set tmargin 4
# set lmargin 1

# global setting
set pointsize 1
set size 1,1
set offset -0.3,-0.3,0,0

# legend
unset key
set key outside left Left reverse enhanced autotitles columnhead  nobox
set key above
set key samplen 0.5 width -4 font ",20"
set key vertical maxrows 1
set key width -3.5

# x-axis
set xlabel font ",15" offset 0,-1.2
set xtics font ",24" rotate by 0 offset 0,-0.2
set xtics ("Baseline" 0, "CVM+PI" 1, "+ZC" 2, "+PRPR" 3, "Bifrost" 4)
# set xlabel "Memcached 1vCPU-256KB" font ",15"
# set xrange [-2:10]

# y-axis
set ylabel "Breakdown(%)" font ",20" offset -0.5,0
set yrange [0:100]
set ytics 0, 20, 100 font ",17"
set grid ytics lw 2

# histogram
set style data histograms 
set style histogram rowstacked gap 2
set style fill pattern border -1 
set boxwidth 0.5 relative


########### LABEL ##########
# baseline
set label "32.91" at -0.23,16 front font ",22" ##1
set label "66.65" at -0.23,62 front font ",22" ##2

# cvm
set label "18.87" at 0.76,12 front font ",22" ##3
set label "38.47" at 0.76,40 front font ",22" ##4
set label "41.55" at 0.76,78 front font ",22" ##5

# zc
set label "33.58" at 1.77,18 front font ",22" ##6
set label "62.77" at 1.77,70 front font ",22" ##7

# gro
set label "23.01" at 2.76,12 front font ",22" ##8
set label "26.66" at 2.76,37 front font ",22" ##9
set label "49.15" at 2.76,74 front font ",22" ##10

# zc+gro
set label "22.26" at 3.76,13 front font ",22" ##11
set label "74.25" at 3.76,60 front font ",22" ##12

########### LABEL ##########

plot newhistogram "" offset 0, 0.5,  "res/4vcpu.res"  \
        using 2 t "VM Exit"    fs pattern 3 ls 1 lc rgb '#999999' lw 2,\
     "" using 3 t "SWIOTLB" fs pattern 3 ls 1 lc rgb '#FFBE7A' lw 2,\
     "" using 4 t "Pkt Processing"  fs pattern 3 ls 1 lc rgb '#8ECFC9' lw 2,\
     "" using 5 t "App Workloads"  fs pattern 3 ls 1 lc rgb '#FA7F6F' lw 2,\
