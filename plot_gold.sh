#!/bin/bash

plot_ask() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="${lower}_ask_price.png"

    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), ask
     FROM gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > plotdata_ask.txt

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold Ask Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "Ask Price ($currency)"

plot "plotdata_ask.txt" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'purple' lw 2 title 'Ask Price'
EOF

    echo "Generated $outfile"
}
