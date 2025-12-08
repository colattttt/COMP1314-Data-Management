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

# USD SECTION
echo "================== USD =================="

usd_ask=$($GREP -oP '"symbol":"AU".*?"ask":\K[0-9.]+' "$RAW" | $HEAD -1)
usd_bid=$($GREP -oP '"symbol":"AU".*?"bid":\K[0-9.]+' "$RAW" | $HEAD -1)
usd_high=$($GREP -oP '"symbol":"AU".*?"high":\K[0-9.]+' "$RAW" | $HEAD -1)
usd_low=$($GREP -oP '"symbol":"AU".*?"low":\K[0-9.]+' "$RAW" | $HEAD -1)
usd_change=$($GREP -oP '"symbol":"AU".*?"change":\K-?[0-9.]+' "$RAW" | $HEAD -1)
usd_chg_pct=$($GREP -oP '"symbol":"AU".*?"changePercentage":\K-?[0-9.]+' "$RAW" | $HEAD -1)
currency=$($GREP -oP '"currency":"\K[A-Z]+' "$RAW" | $HEAD -1)

usd_ask_fmt=$(printf "%.2f" "$usd_ask")
usd_bid_fmt=$(printf "%.2f" "$usd_bid")
usd_high_fmt=$(printf "%.2f" "$usd_high")
usd_low_fmt=$(printf "%.2f" "$usd_low")
usd_change_fmt=$(printf "%+.2f" "$usd_change")
usd_chg_pct_fmt=$(printf "%+.2f%%" "$usd_chg_pct")

units=($($GREP -oP '(?<=capitalize">)[A-Za-z]+' "$RAW"))
prices=($($GREP -oP '(?<=justify-self-end">)[0-9,]+\.[0-9]+' "$RAW"))

usd_ounce="${prices[0]//,/}"
usd_gram="${prices[1]//,/}"
usd_kilo="${prices[2]//,/}"
usd_penny="${prices[3]//,/}"
usd_tola="${prices[4]//,/}"
usd_tael="${prices[5]//,/}"

echo "============ LIVE GOLD PRICE ============"
echo "Last Updated: $nyt_time"
echo "========================================="
echo
echo "================== USD =================="
echo "Currency           : $currency"
echo "Local Timestamp    : $current_time"
echo "Ask Price          : $usd_ask_fmt"
echo "Bid Price          : $usd_bid_fmt"
echo "Day High           : $usd_high_fmt"
echo "Day Low            : $usd_low_fmt"
echo "Change             : $usd_change_fmt"
echo "Change Percentage  : $usd_chg_pct_fmt"
echo "-----------------------------------------"
echo
echo "Price by Weight Unit:"
echo "1. Ounce           : $usd_ounce"
echo "2. Gram            : $usd_gram"
echo "3. Kilo            : $usd_kilo"
echo "4. Pennyweight     : $usd_penny"
echo "5. Tola            : $usd_tola"
echo "6. Tael            : $usd_tael"
echo "========================================="
echo

USD_GOLD_ID=$($MYSQL -u root -p1234 -N -B gold_tracker <<EOF
INSERT INTO gold_prices (
    currency_id, ask_price, bid_price, high_price, low_price,
    change_value, change_percent,
    timestamp_local, timestamp_ny
) VALUES (
    1,
    "$usd_ask_fmt",
    "$usd_bid_fmt",
    "$usd_high_fmt",
    "$usd_low_fmt",
    "$usd_change_fmt",
    "$usd_chg_pct_fmt",
    "$current_time",
    "$nyt_time"
);
SELECT LAST_INSERT_ID();
EOF
)

usd_currency_id=1   # USD
$MYSQL -u root -p1234 gold_tracker <<EOF
INSERT INTO gold_unit_prices (currency_id, gold_id, unit_id, price) VALUES
($usd_currency_id, $USD_GOLD_ID, 1, "$usd_ounce"),
($usd_currency_id, $USD_GOLD_ID, 2, "$usd_gram"),
($usd_currency_id, $USD_GOLD_ID, 3, "$usd_kilo"),
($usd_currency_id, $USD_GOLD_ID, 4, "$usd_penny"),
($usd_currency_id, $USD_GOLD_ID, 5, "$usd_tola"),
($usd_currency_id, $USD_GOLD_ID, 6, "$usd_tael");
EOF

# USD → OTHER CURRENCIES
extract_usdtoc() {
    $GREP -oP "\"$1\".*?usdtoc\":\K[0-9.]+" "$RAW" | $HEAD -1
}

currencies=(AUD CAD JPY)

for cur in "${currencies[@]}"; do

    rate=$(extract_usdtoc "$cur")
    [[ -z "$rate" ]] && continue

    # Convert main prices
    ask=$(printf "%.2f" "$(echo "$usd_ask/$rate" | bc -l)")
    bid=$(printf "%.2f" "$(echo "$usd_bid/$rate" | bc -l)")
    high=$(printf "%.2f" "$(echo "$usd_high/$rate" | bc -l)")
    low=$(printf "%.2f" "$(echo "$usd_low/$rate" | bc -l)")
    change=$(printf "%+.2f" "$(echo "$usd_change/$rate" | bc -l)")
    change_pct="$usd_chg_pct_fmt"

    # Convert weight-unit prices
    converted_ounce=$(printf "%.2f" "$(echo "$usd_ounce/$rate" | bc -l)")
    converted_gram=$(printf "%.2f" "$(echo "$usd_gram/$rate" | bc -l)")
    converted_kilo=$(printf "%.2f" "$(echo "$usd_kilo/$rate" | bc -l)")
    converted_penny=$(printf "%.2f" "$(echo "$usd_penny/$rate" | bc -l)")
    converted_tola=$(printf "%.2f" "$(echo "$usd_tola/$rate" | bc -l)")
    converted_tael=$(printf "%.2f" "$(echo "$usd_tael/$rate" | bc -l)")

    # DISPLAY CONVERTED CURRENCY
    echo "================== $cur =================="
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
    echo "1. Ounce           : $converted_ounce"
    echo "2. Gram            : $converted_gram"
    echo "3. Kilo            : $converted_kilo"
    echo "4. Pennyweight     : $converted_penny"
    echo "5. Tola            : $converted_tola"
    echo "6. Tael            : $converted_tael"
    echo "========================================="
    echo

case "$cur" in
  AUD) CURR_ID=2 ;;
  CAD) CURR_ID=3 ;;
  JPY) CURR_ID=4 ;;
esac

# 1. Insert gold_prices row
GOLD_ID=$($MYSQL -u root -p1234 -N -B gold_tracker <<EOF
INSERT INTO gold_prices (
    currency_id, ask_price, bid_price, high_price, low_price,
    change_value, change_percent,
    timestamp_local, timestamp_ny
) VALUES (
    $CURR_ID,
    "$ask",
    "$bid",
    "$high",
    "$low",
    "$change",
    "$change_pct",
    "$current_time",
    "$nyt_time"
);
SELECT LAST_INSERT_ID();
EOF
)

# 2. Insert 6 unit prices
$MYSQL -u root -p1234 gold_tracker <<EOF
INSERT INTO gold_unit_prices (currency_id, gold_id, unit_id, price) VALUES
($CURR_ID, $GOLD_ID, 1, "$converted_ounce"),
($CURR_ID, $GOLD_ID, 2, "$converted_gram"),
($CURR_ID, $GOLD_ID, 3, "$converted_kilo"),
($CURR_ID, $GOLD_ID, 4, "$converted_penny"),
($CURR_ID, $GOLD_ID, 5, "$converted_tola"),
($CURR_ID, $GOLD_ID, 6, "$converted_tael");
EOF
done