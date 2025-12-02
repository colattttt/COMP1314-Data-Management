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

echo "Currency           : $currency"
echo "Local Timestamp    : $current_time"
echo "Ask Price          : $usd_ask_fmt"
echo "Bid Price          : $usd_bid_fmt"
echo "Day High           : $usd_high_fmt"
echo "Day Low            : $usd_low_fmt"
echo "Change             : $usd_change_fmt"
echo "Change Percentage  : $usd_chg_pct_fmt"
echo "-----------------------------------------"

echo "Price by Weight Unit:"
units=($(grep -oP '(?<=capitalize">)[A-Za-z]+' raw.html))
prices=($(grep -oP '(?<=justify-self-end">)[0-9,]+\.[0-9]+' raw.html))

count=1
for i in "${!units[@]}"; do
    printf "%d. %-12s: %s\n" "$count" "${units[$i]^}" "${prices[$i]}"
    ((count++))
done
echo "========================================="
echo

usd_ounce="${prices[0]//,/}"
usd_gram="${prices[1]//,/}"
usd_kilo="${prices[2]//,/}"
usd_penny="${prices[3]//,/}"
usd_tola="${prices[4]//,/}"
usd_tael="${prices[5]//,/}"

mysql -u root -p1234 gold_tracker <<EOF
INSERT INTO gold_prices (
    currency, ask, bid, high, low,
    change_value, change_percent,
    timestamp_local, timestamp_ny,
    ounce, gram, kilo, pennyweight, tola, tael
) VALUES (
    "USD",
    "$usd_ask_fmt", "$usd_bid_fmt", "$usd_high_fmt", "$usd_low_fmt",
    "$usd_change_fmt", "$usd_chg_pct_fmt",
    "$current_time", "$nyt_time",
    "$usd_ounce", "$usd_gram", "$usd_kilo",
    "$usd_penny", "$usd_tola", "$usd_tael"
);
EOF

# Extract USD → Currency Rates
extract_usdtoc() {
    grep -oP "\"$1\".*?usdtoc\":\K[0-9.]+" raw.html | head -1
}

currencies=(AUD CAD JPY)

for cur in "${currencies[@]}"; do

done