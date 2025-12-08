#!/bin/bash

# Plot ask price function
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

# Plot bid price function
plot_bid() {
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="${lower}_bid_price.png"

    # Export DATE, TIME, BID (normalized DB)
    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), bid
     FROM gold_prices
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > plotdata_bid.txt

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold Bid Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "Bid Price ($currency)"

plot "plotdata_bid.txt" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'blue' lw 2 title 'Bid Price'
EOF

    echo "Generated $outfile"
}

# Plot high price function
plot_high() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="${lower}_high_price.png"

    # Export DATE, TIME, HIGH
    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), high
     FROM gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > plotdata_high.txt

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold High Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "High Price ($currency)"

plot "plotdata_high.txt" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'orange' lw 2 title 'High Price'
EOF

    echo "Generated $outfile"
}

# Plot low price function
plot_low() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="${lower}_low_price.png"

    # Export DATE, TIME, LOW PRICE
    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), low_price
     FROM gold_tracker.gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > plotdata_low.txt

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold Low Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "Low Price ($currency)"

plot "plotdata_low.txt" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'red' lw 2 title 'Low Price'
EOF

    echo "Generated $outfile"
}

# Command handler
if [ "$1" = "ask" ]; then
    plot_ask "$2"
elif [ "$1" = "bid" ]; then
    plot_bid "$2"
elif [ "$1" = "high" ]; then
    plot_high "$2"
elif [ "$1" = "low" ]; then
    plot_low "$2"
else
    echo "Usage:"
    echo "  ./plot.sh ask USD"
    echo "  ./plot.sh bid USD"
    echo "  ./plot.sh high USD"
    echo "  ./plot.sh low USD"
    echo "Example currencies: USD, AUD, CAD, JPY"
fi