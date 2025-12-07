#!/bin/bash

plot_usd_price() {

    mysql -u root -p1234 -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), ask
     FROM gold_tracker.gold_prices 
     WHERE currency='USD' 
     ORDER BY timestamp_local" > plotdata.txt

gnuplot << EOF
set terminal png size 1920,1080
set output "usd_price.png"
set title "USD Gold Ask Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "USD"

plot "plotdata.txt" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'purple' lw 2 title 'Ask Price'
EOF

echo "Generated usd_price.png"
}

case "$1" in
  usd_price)
    plot_usd_price
    ;;
  *)
    echo "Usage: ./plot.sh usd_price"
    ;;
esac
