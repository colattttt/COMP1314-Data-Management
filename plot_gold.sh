#!/bin/bash

outdir="plot_images"
mkdir -p "$outdir"

datadir="plot_data"
mkdir -p "$datadir"

# Plot ask price function
plot_ask() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_ask_price.png"
    datafile="$datadir/plotdata_ask.txt"

    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), ask_price
     FROM gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold Ask Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "Ask Price ($currency)"

set grid xtics ytics back lw 1 lc rgb "#DDDDDD"

plot "$datafile" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'purple' lw 2 title 'Ask Price'
EOF

    echo "Generated $outfile"
}

# Plot bid price function
plot_bid() {
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_bid_price.png"
    datafile="$datadir/plotdata_bid.txt"

    # Export DATE, TIME, BID (normalized DB)
    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), bid_price
     FROM gold_prices
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold Bid Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "Bid Price ($currency)"

set grid xtics ytics back lw 1 lc rgb "#DDDDDD"

plot "$datafile" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'blue' lw 2 title 'Bid Price'
EOF

    echo "Generated $outfile"
}

# Plot high price function
plot_high() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_high_price.png"
    datafile="$datadir/plotdata_high.txt"

    # Export DATE, TIME, HIGH
    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), high_price
     FROM gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold High Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "High Price ($currency)"

set grid xtics ytics back lw 1 lc rgb "#DDDDDD"

plot "$datafile" using (strcol(1)." ".strcol(2)):3 \
     with linespoints lt rgb 'orange' lw 2 title 'High Price'
EOF

    echo "Generated $outfile"
}

# Plot low price function
plot_low() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_low_price.png"
    datafile="$datadir/plotdata_low.txt"

    # Export DATE, TIME, LOW PRICE
    mysql -u root -p1234 -D gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), low_price
     FROM gold_tracker.gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

gnuplot << EOF
set terminal png size 1920,1080
set output "$outfile"
set title "$currency Gold Low Price Over Time"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"

set xlabel "Time"
set ylabel "Low Price ($currency)"

set grid xtics ytics back lw 1 lc rgb "#DDDDDD"

plot "$datafile" using (strcol(1)." ".strcol(2)):3 \
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
    echo "  ./plot_gold.sh ask USD"
    echo "  ./plot_gold.sh bid USD"
    echo "  ./plot_gold.sh high USD"
    echo "  ./plot_gold.sh low USD"
    echo "Example currencies: USD, AUD, CAD, JPY"
fi