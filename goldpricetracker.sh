#!/bin/bash

cd "$(dirname "$0")"

CURL=/usr/bin/curl
GREP=/usr/bin/grep
AWK=/usr/bin/awk
MYSQL=/usr/bin/mysql
DATE=/usr/bin/date
SLEEP=/bin/sleep
HEAD=/usr/bin/head

RAW="./raw.html"
LOG="./gold.log"

# Progress Bar
echo -n "Fetching live data "
for i in {1..20}; do
    echo -n "▮"
    sleep 0.05
done
echo -e "  Done ✓"
echo

# Fetch HTML
$CURL -sS https://www.kitco.com/charts/gold > "$RAW"

nyt_time=$(TZ="America/New_York" $DATE '+%b %d, %Y - %H:%M NY Time')
current_time=$($DATE '+%Y-%m-%d %H:%M:%S')

echo "============ LIVE GOLD PRICE ============"
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

    echo "Currency           : $cur"
    echo "Local Timestamp    : $current_time"
    echo "Ask Price          : $ask"
    echo "Bid Price          : $bid"
    echo "Day High           : $high"
    echo "Day Low            : $low"
    echo "Change             : $change"
    echo "Change Percentage  : $change_pct"
    echo "Converted From     : USD → $cur"
    echo "-----------------------------------------"
    echo "Price by Weight Unit ($cur):"
    count=1
    for i in "${!units[@]}"; do
    usd_val="${prices[$i]//,/}"     # remove commas
    converted_val=$(awk "BEGIN {printf \"%.2f\", $usd_val / $rate}")
    printf "%d. %-12s: %s\n" "$count" "${units[$i]^}" "$converted_val"
    ((count++))
    done
    echo "========================================="
    echo

    converted_ounce=$(awk "BEGIN {printf \"%.2f\", $usd_ounce / $rate}")
    converted_gram=$(awk "BEGIN {printf \"%.2f\", $usd_gram / $rate}")
    converted_kilo=$(awk "BEGIN {printf \"%.2f\", $usd_kilo / $rate}")
    converted_penny=$(awk "BEGIN {printf \"%.2f\", $usd_penny / $rate}")
    converted_tola=$(awk "BEGIN {printf \"%.2f\", $usd_tola / $rate}")
    converted_tael=$(awk "BEGIN {printf \"%.2f\", $usd_tael / $rate}")

mysql -u root -p1234 gold_tracker <<EOF
INSERT INTO gold_prices (
    currency, ask, bid, high, low,
    change_value, change_percent,
    timestamp_local, timestamp_ny,
    ounce, gram, kilo, pennyweight, tola, tael
) VALUES (
    "$cur",
    "$ask", "$bid", "$high", "$low",
    "$change", "$change_pct",
    "$current_time", "$nyt_time",
    "$converted_ounce", "$converted_gram", "$converted_kilo",
    "$converted_penny", "$converted_tola", "$converted_tael"
);
EOF
done

REPO="/mnt/c/Users/pohsh/GitHub/COMP1314-Data-Management"
TARGET="$REPO/raw.html"

echo "Updating to GitHub repository..."

# Copy raw.html into your Git repo
cp raw.html "$TARGET"

# Go to repo
cd "$REPO"

# Add & commit
git add raw.html
git commit -m "Updated raw.html at $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1

# Push to GitHub
git push >/dev/null 2>&1

echo "GitHub update completed"
echo