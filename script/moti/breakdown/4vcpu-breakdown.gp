#!/usr/bin/gnuplot
reset
set output "../../../figures/fig-03.eps"
set terminal postscript "Helvetica,14" eps enhance dl 2 color size 7,1.8

set bmargin 5.3
set tmargin 3
set lmargin 10
set rmargin 0

set pointsize 1
set size 1,1

#load 'line-style.plt'

##
# unset key
# set key outside top invert enhanced autotitles columnhead nobox
# set key samplen 0.5 spacing 1 width 0.5 height 0.2 font ",15"
# set key at 10,125
# set key vertical maxrows 2

unset key
set key outside left Lef reverse invert enhanced autotitles columnhead  nobox
set key above
set key samplen 0.5 width -3.5 font ",25"
set key vertical maxrows 1
set key at 3.1,120
set key spacing -1
##

set ylabel "Breakdown(%)" font ",30" offset -0.9,0
set xlabel font ",15" offset 0,-1.7
set xlabel "Memcached 4vCPU-256KB" font ",30"

set yrange [0:100]
set ytics format "%g"
#set ytics 150 font ",20"
set xrange [-0.5:3.5]
set xtics font ",23" rotate by 0 offset 0,-0.5 autojustify
set xtics ("CVM's Baseline" 0, "CVM    " 1, "CVM+PI's Baseline" 2, "      CVM+PI" 3)
set ytics 0, 20, 100 font ",20"
# unset xtics
# set xtics format ""

#set xtics font ",18" rotate by 0 offset 0,0

set grid ytics lw 2

set style data histograms 
set style histogram rowstacked gap 2
set style fill pattern border -1 
set boxwidth 0.6 relative

#set label "618" at  -0.2,680 front rotate by 0 font ",20"
#set label "214" at  0.8,260 front rotate by 0 font ",20"

#set style line 2 lc rgb "#8ECFC9" lt 3 lw 4 pt 5 ps 1.5 pi -1  ## solid box
#set style line 3 lc rgb "#FFBE7A" lt 3 lw 4 pt 5 ps 1.5 pi -1  ## solid box
#set style line 4 lc rgb "#FA7F6F" lt 3 lw 4 pt 5 ps 1.5 pi -1  ## solid box
#set style line 5 lc rgb "#82B0D2" lt 3 lw 4 pt 5 ps 1.5 pi -1  ## solid box

# CVM
set label "13.20" at -0.23,8 front font ",25" ##1
set label "28.61" at -0.23,28 front font ",25" ##2
set label "58.19" at -0.23,72 front font ",25" ##3

set label "21.12" at 0.77,10 front font ",25" ##4
set label "13.40" at 0.77,26 front font ",25" ##5
set label "26.78" at 0.77,47 front font ",25" ##6
set label "38.70" at 0.77,81 front font ",25" ##7

# Posted-IRQ
set label "32.91" at 1.77,16 front font ",25" ##8
set label "66.65" at 1.77,67 front font ",25" ##9

set label "18.87" at 2.75,10 front font ",25" ##10
set label "38.47" at 2.75,40 front font ",25" ##11
set label "41.55" at 2.77,78 front font ",25" ##12

set style arrow 1 head filled size screen 0.03,15 ls 2 lc '#FFBE7A'
set arrow 1 from 3.3,20.5 to 4.13,67 arrowstyle 1
set arrow 2 from 3.3,1.11 to 4.13,2 arrowstyle 1

set multiplot
set size .6,1
plot newhistogram "" offset 0, -2, "res/4vcpu-cvm.res" using 2         \
         t "VM Exit"    fs pattern 3 ls 1 lc rgb '#999999' lw 2,\
     "" using 3         \
     t "SWIOTLB" fs pattern 3 ls 1 lc rgb '#FFBE7A' lw 2,\
     "" using 4         \
     t "Pkt Processing"  fs pattern 3 ls 1 lc rgb '#8ECFC9' lw 2,\
     "" using 5         \
     t "App Workloads"  fs pattern 3 ls 1 lc rgb '#FA7F6F' lw 2,\
     newhistogram "" at 2, "res/4vcpu-postirq.res" using 2         \
         t ""    fs pattern 3 ls 1 lc rgb '#999999' lw 2,\
    "" using 3        \
     t "" fs pattern 3 ls 1 lc rgb '#FFBE7A' lw 2,\
     "" using 4         \
     t ""  fs pattern 3 ls 1 lc rgb '#8ECFC9' lw 2,\
     "" using 5         \
     t ""  fs pattern 3 ls 1 lc rgb '#FA7F6F' lw 2,\

unset label
unset ylabel
set origin .6,0.02

set size .25,.8
unset arrow
unset key
set label "51.17" at -0.37,26 front font ",25" ##13
set label "48.83" at -0.37,73 front font ",25" ##14
set key outside left Left reverse enhanced autotitles columnhead  nobox
set key above
set key samplen 0.5 width -2 font ",25"
set key vertical maxrows 1 spacing -2
set key at -0,135
unset xrange
unset ytics
unset xlabel
set y2label "Breakdown(%)" font ",30" offset 4,0
set y2range [0:100]
set y2tics format "%g" font ",23"
set y2tics 0,50,100
set grid y2tics lw 2
# set ytics mirror
set xtics format ""
unset xtics
set boxwidth 0.8 relative
plot newhistogram "SWIOTLB" font ",30" offset 0, -3, "res/4vcpu-swiotlb.res" using 2         \
         t "Memcpy"    fs pattern 3 ls 1 lc rgb '#F1E2CC' lw 2,\
     "" using 3         \
     t "Metadata" fs pattern 3 ls 1 lc rgb '#A6CEE3' lw 2,\
    #  newhistogram "optIRQ" offset 0,  0.5, "res/4vcpu-optirq.res" using 2         \
    #      t ""    fs pattern 3 ls 1 lc rgb '#999999' lw 2,\
    # "" using 3        \
    #  t "" fs pattern 3 ls 1 lc rgb '#FFBE7A' lw 2,\
    #  "" using 4         \
    #  t ""  fs pattern 3 ls 1 lc rgb '#8ECFC9' lw 2,\
    #  "" using 5         \
    #  t ""  fs pattern 3 ls 1 lc rgb '#FA7F6F' lw 2,\
    #  "" using 6         \
    #  t ""  fs pattern 3 ls 1 lc rgb '#4575B4' lw 2,\
