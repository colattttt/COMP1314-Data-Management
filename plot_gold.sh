#!/bin/bash

# Create directories for generated plot images and temporary data files
outdir="plot_images"
mkdir -p "$outdir"

datadir="plot_data"
mkdir -p "$datadir"

# Generate a time-series plot for ask price
plot_ask() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_ask_price.png"
    datafile="$datadir/plotdata_ask.txt"

    # Export ask price data from the database
    mysql gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), ask_price
     FROM gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

# Plot ask price using gnuplot
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

    # Record plot generation in log file
    filename=$(basename "$outfile")
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Generated $filename" >> logs/plot.log
}

# Generate a time-series plot for bid price
plot_bid() {
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_bid_price.png"
    datafile="$datadir/plotdata_bid.txt"

    # Export bid price data from the database
    mysql gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), bid_price
     FROM gold_prices
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

# Plot bid price using gnuplot
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

    # Record plot generation in log file
    filename=$(basename "$outfile")
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Generated $filename" >> logs/plot.log
}

# Generate a time-series plot for daily high price
plot_high() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_high_price.png"
    datafile="$datadir/plotdata_high.txt"

    # Export high price data from the database
    mysql gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), high_price
     FROM gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

# Plot high price using gnuplot
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
     with linespoints lt rgb 'green' lw 2 title 'High Price'
EOF

    # Record plot generation in log file
    filename=$(basename "$outfile")
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Generated $filename" >> logs/plot.log
}

# Generate a time-series plot for daily low price
plot_low() { 
    currency=$1
    lower=$(echo "$currency" | tr 'A-Z' 'a-z')
    outfile="$outdir/${lower}_low_price.png"
    datafile="$datadir/plotdata_low.txt"

    # Export low price data from the database
    mysql gold_tracker -N -B -e \
    "SELECT DATE(timestamp_local), TIME(timestamp_local), low_price
     FROM gold_tracker.gold_prices 
     WHERE currency_id = (SELECT currency_id FROM currencies WHERE currency_code='$currency')
     ORDER BY timestamp_local" > "$datafile"

# Plot low price using gnuplot
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

    # Record plot generation in log file
    filename=$(basename "$outfile")
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Generated $filename" >> logs/plot.log
}

# Handle user input and call the appropriate plot function
if [ "$1" = "ask" ]; then
    plot_ask "$2"
elif [ "$1" = "bid" ]; then
    plot_bid "$2"
elif [ "$1" = "high" ]; then
    plot_high "$2"
elif [ "$1" = "low" ]; then
    plot_low "$2"
else
    # Display usage instructions if input is invalid
    echo "How to Use This Script:"
    echo "  ./plot_gold.sh <type> <currency>"
    echo
    echo "Price Types You Can Choose:"
    echo "  ask      Plot Ask Price over time"
    echo "  bid      Plot Bid Price over time"
    echo "  high     Plot High Price over time"
    echo "  low      Plot Low Price over time"
    echo
    echo "Example Command:"
    echo "  ./plot_gold.sh ask USD"
    echo
    echo "Supported currencies:"
    echo "  USD, AUD, CAD, JPY"
fi