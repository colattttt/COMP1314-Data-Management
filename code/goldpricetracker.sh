#!/bin/bash

curl -s -H "User-Agent: Mozilla/5.0" https://www.kitco.com/charts/gold > raw.html

echo "============ LIVE GOLD PRICE ============"

nyt_raw=$(grep -oP '[A-Z][a-z]{2} \d{1,2}, \d{4} – \d{2}:\d{2} NY Time' raw.html | head -1)

echo "Last Updated:  $nyt_raw"
echo "-----------------------------------------"

# Ask & Bid from the main section
ask=$(grep -oP '"symbol":"AU".*?"ask":\K[0-9.]+' raw.html | head -1)
bid=$(grep -oP '"symbol":"AU".*?"bid":\K[0-9.]+' raw.html | head -1)


# Force to 2 decimal places
ask_fmt=$(printf "%.2f" "$ask")
bid_fmt=$(printf "%.2f" "$bid")

currency=$(grep -oP '"currency":"\K[A-Z]+' raw.html | head -1)

timestamp_raw=$(grep -oP '"timestamp":\K[0-9]+' raw.html | head -1)
timestamp=$(date -d "@$timestamp_raw" "+%Y-%m-%d %H:%M:%S")

echo "Currency:   $currency"
echo "Timestamp:  $timestamp"
echo "-----------------------------------------"
echo "Bid Price:  $bid_fmt"
echo "Ask Price:  $ask_fmt"
echo "-----------------------------------------"
echo "Prices by Unit:"

# Extract unit names (ounce, gram, kilo…)
units=($(grep -oP '(?<=capitalize">)[A-Za-z]+' raw.html | tr 'A-Z' 'a-z'))

# Extract unit prices (4,133.60 etc.)
prices=($(grep -oP '(?<=justify-self-end">)[0-9,]+\.[0-9]+' raw.html))

# Print them nicely
for i in "${!units[@]}"; do
    printf "  • %-12s %s\n" "${units[$i]^}" "${prices[$i]}"
done

echo "========================================="