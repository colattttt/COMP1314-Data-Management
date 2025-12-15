#!/bin/bash

# Ensure the script always runs from its own directory
cd "$(dirname "$0")"

# Absolute command paths to avoid Cron environment issues
curl=/usr/bin/curl
grep=/usr/bin/grep
awk=/usr/bin/awk
mysql=/usr/bin/mysql
date=/usr/bin/date
sleep=/bin/sleep
head=/usr/bin/head
bc=/usr/bin/bc

# File locations
raw="./raw.html"
error_log="./logs/goldtracker_error.log"

# Writes timestamped error messages to the error log file
log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo "$msg" >> "$error_log"
}

# Download live gold price HTML from Kitco
if ! curl -sS "https://www.kitco.com/charts/gold" -o "$raw"; then
    log_error "Failed to fetch Kitco HTML – network down or website unreachable."
    exit 1
fi

# Ensure downloaded file contains data
if [[ ! -s "$raw" ]]; then
    log_error "Downloaded HTML is empty — possible website block or downtime."
    exit 1
fi

# Display a progress bar for user feedback
echo -n "Fetching live data "
for i in {1..20}; do
    echo -n "▮"
    sleep 0.05
done
echo -e "  Done ✓"
echo

# Generate local time and New York market time
nyt_time=$(TZ="America/New_York" $date '+%b %d, %Y - %H:%M NY Time')
current_time=$($date '+%Y-%m-%d %H:%M:%S')

# Extract USD gold prices from HTML
usd_ask=$($grep -oP '"symbol":"AU".*?"ask":\K[0-9.]+' "$raw" | $head -1)
usd_bid=$($grep -oP '"symbol":"AU".*?"bid":\K[0-9.]+' "$raw" | $head -1)
usd_high=$($grep -oP '"symbol":"AU".*?"high":\K[0-9.]+' "$raw" | $head -1)
usd_low=$($grep -oP '"symbol":"AU".*?"low":\K[0-9.]+' "$raw" | $head -1)
usd_change=$($grep -oP '"symbol":"AU".*?"change":\K-?[0-9.]+' "$raw" | $head -1)
usd_chg_pct=$($grep -oP '"symbol":"AU".*?"changePercentage":\K-?[0-9.]+' "$raw" | $head -1)
currency=$($grep -oP '"currency":"\K[A-Z]+' "$raw" | $head -1)

# Stop if critical values are missing
if [[ -z "$usd_ask" || -z "$usd_bid" || -z "$usd_high" || -z "$usd_low" ]]; then
    log_error "Missing essential USD values — Kitco HTML structure may have changed."
    exit 1
fi

if [[ -z "$usd_change" || -z "$usd_chg_pct" ]]; then
    log_error "Missing change / changePercentage — structure changed."
    exit 1
fi

# Format values for display and database storage
usd_ask_fmt=$(printf "%.2f" "$usd_ask")
usd_bid_fmt=$(printf "%.2f" "$usd_bid")
usd_high_fmt=$(printf "%.2f" "$usd_high")
usd_low_fmt=$(printf "%.2f" "$usd_low")
usd_change_fmt=$(printf "%+.2f" "$usd_change")
usd_chg_pct_fmt=$(printf "%+.2f%%" "$usd_chg_pct")

# Extract gold prices by weight unit
units=($($grep -oP '(?<=capitalize">)[A-Za-z]+' "$raw"))
prices=($($grep -oP '(?<=justify-self-end">)[0-9,]+\.[0-9]+' "$raw"))

# Expect exactly 6 unit prices
if [[ ${#prices[@]} -ne 6 ]]; then
    log_error "Weight unit extraction failed — expected 6 items, got ${#prices[@]}."
    exit 1
fi

usd_ounce="${prices[0]//,/}"
usd_gram="${prices[1]//,/}"
usd_kilo="${prices[2]//,/}"
usd_penny="${prices[3]//,/}"
usd_tola="${prices[4]//,/}"
usd_tael="${prices[5]//,/}"

# Display USD gold price report
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

# Insert USD prices into gold_prices table
usd_gold_id=$($mysql -N -B gold_tracker <<EOF 2>>"$error_log"
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

if [[ -z "$usd_gold_id" ]]; then
    log_error "MySQL Insert Failed: Could not store USD gold_prices row."
    exit 1
fi

# Insert USD weight-unit prices
usd_currency_id=1 
$mysql gold_tracker <<EOF 2>>"$error_log"
INSERT INTO gold_unit_prices (currency_id, gold_id, unit_id, price) VALUES
($usd_currency_id, $usd_gold_id, 1, "$usd_ounce"),
($usd_currency_id, $usd_gold_id, 2, "$usd_gram"),
($usd_currency_id, $usd_gold_id, 3, "$usd_kilo"),
($usd_currency_id, $usd_gold_id, 4, "$usd_penny"),
($usd_currency_id, $usd_gold_id, 5, "$usd_tola"),
($usd_currency_id, $usd_gold_id, 6, "$usd_tael");
EOF

# Extract USD to target currency exchange rate
extract_usdtoc() {
    $grep -oP "\"$1\".*?usdtoc\":\K[0-9.]+" "$raw" | $head -1
}

# Process each non-USD currency
currencies=(AUD CAD JPY)

for cur in "${currencies[@]}"; do

    # Get exchange rate for USD to target currency
    rate=$(extract_usdtoc "$cur")
    if [[ -z "$rate" ]]; then
        log_error "Missing exchange rate for $cur"
        continue
    fi

    # Convert main market prices from USD
    ask=$(printf "%.2f" "$(echo "$usd_ask/$rate" | bc -l)")
    bid=$(printf "%.2f" "$(echo "$usd_bid/$rate" | bc -l)")
    high=$(printf "%.2f" "$(echo "$usd_high/$rate" | bc -l)")
    low=$(printf "%.2f" "$(echo "$usd_low/$rate" | bc -l)")
    change=$(printf "%+.2f" "$(echo "$usd_change/$rate" | bc -l)")
    change_pct="$usd_chg_pct_fmt"

    # Convert gold prices by weight unit
    converted_ounce=$(printf "%.2f" "$(echo "$usd_ounce/$rate" | bc -l)")
    converted_gram=$(printf "%.2f" "$(echo "$usd_gram/$rate" | bc -l)")
    converted_kilo=$(printf "%.2f" "$(echo "$usd_kilo/$rate" | bc -l)")
    converted_penny=$(printf "%.2f" "$(echo "$usd_penny/$rate" | bc -l)")
    converted_tola=$(printf "%.2f" "$(echo "$usd_tola/$rate" | bc -l)")
    converted_tael=$(printf "%.2f" "$(echo "$usd_tael/$rate" | bc -l)")

    # Display converted currency report
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

# Match currency code to database identifier
case "$cur" in
  AUD) curr_id=2 ;;
  CAD) curr_id=3 ;;
  JPY) curr_id=4 ;;
esac

# Store converted market prices and retrieve record ID
gold_id=$($mysql -N -B gold_tracker <<EOF 2>>"$error_log"
INSERT INTO gold_prices (
    currency_id, ask_price, bid_price, high_price, low_price,
    change_value, change_percent,
    timestamp_local, timestamp_ny
) VALUES (
    $curr_id,
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

# Check if insert was successful
if [[ -z "$gold_id" ]]; then
        log_error "MySQL Insert Failed: Could not insert $cur gold_prices"
        continue
    fi

# Store converted weight-unit prices linked to the main record
$mysql gold_tracker <<EOF 2>>"$error_log"
INSERT INTO gold_unit_prices (currency_id, gold_id, unit_id, price) VALUES
($curr_id, $gold_id, 1, "$converted_ounce"),
($curr_id, $gold_id, 2, "$converted_gram"),
($curr_id, $gold_id, 3, "$converted_kilo"),
($curr_id, $gold_id, 4, "$converted_penny"),
($curr_id, $gold_id, 5, "$converted_tola"),
($curr_id, $gold_id, 6, "$converted_tael");
EOF
done