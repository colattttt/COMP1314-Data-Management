#!/bin/bash

# Progress Bar
echo -n "Fetching live data "
for i in {1..20}; do
    echo -n "▮"
    sleep 0.05
done
echo -e "  Done ✓"
echo

# Fetch HTML
curl -sS https://www.kitco.com/charts/gold > raw.html

echo "============ LIVE GOLD PRICE ============"
nyt_time=$(TZ="America/New_York" date '+%b %d, %Y - %H:%M NY Time')
echo "Last Updated: $nyt_time"
echo "========================================="
echo

# USD SECTION
echo "================== USD =================="

usd_ask=$(grep -oP '"symbol":"AU".*?"ask":\K[0-9.]+' raw.html | head -1)
usd_bid=$(grep -oP '"symbol":"AU".*?"bid":\K[0-9.]+' raw.html | head -1)
usd_high=$(grep -oP '"symbol":"AU".*?"high":\K[0-9.]+' raw.html | head -1)
usd_low=$(grep -oP '"symbol":"AU".*?"low":\K[0-9.]+' raw.html | head -1)
usd_change=$(grep -oP '"symbol":"AU".*?"change":\K-?[0-9.]+' raw.html | head -1)
usd_chg_pct=$(grep -oP '"symbol":"AU".*?"changePercentage":\K-?[0-9.]+' raw.html | head -1)

usd_ask_fmt=$(printf "%.2f" "$usd_ask")
usd_bid_fmt=$(printf "%.2f" "$usd_bid")
usd_high_fmt=$(printf "%.2f" "$usd_high")
usd_low_fmt=$(printf "%.2f" "$usd_low")
usd_change_fmt=$(printf "%+.2f" "$usd_change")
usd_chg_pct_fmt=$(printf "%+.2f%%" "$usd_chg_pct")

currency=$(grep -oP '"currency":"\K[A-Z]+' raw.html | head -1)
current_time=$(date '+%Y-%m-%d %H:%M:%S')

echo "Currency: $currency"
echo "Local Timestamp: $current_time"
echo "Ask Price:   $usd_ask_fmt"
echo "Bid Price:   $usd_bid_fmt"
echo "Day High:    $usd_high_fmt"
echo "Day Low:     $usd_low_fmt"
echo "Change:            $usd_change_fmt"
echo "Change Percentage: $usd_chg_pct_fmt"
echo "-----------------------------------------"

echo "Price by Weight Unit:"
units=($(grep -oP '(?<=capitalize">)[A-Za-z]+' raw.html))
prices=($(grep -oP '(?<=justify-self-end">)[0-9,]+\.[0-9]+' raw.html))

for i in "${!units[@]}"; do
    printf "• %-12s %s\n" "${units[$i]^}" "${prices[$i]}"
done

echo "========================================="
echo

# Extract USD → Currency Rates

extract_usdtoc() {
    grep -oP "\"$1\".*?usdtoc\":\K[0-9.]+" raw.html | head -1
}

currencies=(AUD CAD JPY)

for cur in "${currencies[@]}"; do
    echo "================== $cur =================="

    rate=$(extract_usdtoc "$cur")

    if [[ -z "$rate" ]]; then
        echo "$cur data unavailable."
        echo "========================================="
        echo
        continue
    fi

    ask=$(awk "BEGIN {printf \"%.2f\", $usd_ask / $rate}")
    bid=$(awk "BEGIN {printf \"%.2f\", $usd_bid / $rate}")
    high=$(awk "BEGIN {printf \"%.2f\", $usd_high / $rate}")
    low=$(awk "BEGIN {printf \"%.2f\", $usd_low / $rate}")
    change=$(awk "BEGIN {printf \"%+.2f\", $usd_change / $rate}")
    change_pct=$(printf "%+.2f%%" "$usd_chg_pct")

    current_time=$(date '+%Y-%m-%d %H:%M:%S')
done

# Print them nicely
for i in "${!units[@]}"; do
    printf "  • %-12s %s\n" "${units[$i]^}" "${prices[$i]}"
done

echo "========================================="
