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

