#!/bin/bash

API_KEY_FILE_EXC="$CONFIG_DIR/plugins/sensitive-exchange-rate.sh"
if [ -f "$API_KEY_FILE_EXC" ]; then
    source "$API_KEY_FILE_EXC"
else
    echo "Error: '$API_KEY_FILE_EXC' file not found"
    exit 1
fi

# Configuration
CACHE_DIR="/tmp/sketchybar_currency"
CACHE_FILE="$CACHE_DIR/rates_$(date +%Y%m%d).json"
# PREVIOUS_FILE="$CACHE_DIR/rates_$(date -v-1d +%Y%m%d).json"
#API_KEY_EXCHANGE_RATE="YOUR_API_KEY_HERE"  # load from file
WHITE=0xaaffffff

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to cleanup old cache files (keep only last 7 days)
cleanup_cache() {
    find "$CACHE_DIR" -name "rates_*.json" -mtime +7 -delete
}

# Function to fetch exchange rates
fetch_rates() {
    # Using exchangerate-api.com's v6 API
    response=$(curl -s "https://v6.exchangerate-api.com/v6/${API_KEY_EXCHANGE_RATE}/latest/HUF")
    
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        # Save current rates to cache with timestamp
        echo "$response" > "$CACHE_FILE"
        cleanup_cache
        return 0
    fi
    return 1
}

# Function to calculate rate in HUF (inverts the rate since API gives HUF-based rates)
calculate_huf_rate() {
    local rate=$1
    echo "scale=2; 1 / $rate" | bc
}

# Function to determine color based on rate movement
get_color() {
    local current=$1
    local previous=$2
    
    if [ -z "$previous" ] || [ "$current" = "$previous" ]; then
        echo "white"
    elif (( $(echo "$current > $previous" | bc -l) )); then
        echo "0xff28a745"  # Green
    else
        echo "0xffdc3545"  # Red
    fi
}

# Function to update the display
update_display() {
    local current_date=$(date +%Y%m%d)
    local current_cache="$CACHE_DIR/rates_$current_date.json"
    local previous_date=$(date -v-1d +%Y%m%d)
    local previous_cache="$CACHE_DIR/rates_$previous_date.json"

    # Fetch new rates if today's cache doesn't exist
    if [ ! -f "$current_cache" ]; then
        fetch_rates
    fi
    
    # Read current and previous rates
    if [ -f "$current_cache" ]; then
        EUR_RATE=$(calculate_huf_rate $(jq -r '.conversion_rates.EUR' "$current_cache"))
        USD_RATE=$(calculate_huf_rate $(jq -r '.conversion_rates.USD' "$current_cache"))
        TIMESTAMP=$(date -r "$current_cache" "+%H:%M")
        
        if [ -f "$previous_cache" ]; then
            PREV_EUR_RATE=$(calculate_huf_rate $(jq -r '.conversion_rates.EUR' "$previous_cache"))
            PREV_USD_RATE=$(calculate_huf_rate $(jq -r '.conversion_rates.USD' "$previous_cache"))
            
            EUR_COLOR=$(get_color "$EUR_RATE" "$PREV_EUR_RATE")
            USD_COLOR=$(get_color "$USD_RATE" "$PREV_USD_RATE")
        else
            EUR_COLOR="$WHITE"
            USD_COLOR="$WHITE"
        fi
        
        # Format the output for sketchybar with timestamp
        sketchybar -m --set currency_item \
            label="€:${EUR_RATE%.*} \$:${USD_RATE%.*} (${TIMESTAMP})" \
            label.color="$EUR_COLOR"
    else
        sketchybar -m --set currency_item \
            label="Failed to fetch rates" \
            label.color=0xffdc3545
    fi
}

# Handle different execution modes
case "$1" in
    --update)
        update_display
        ;;
    *)
        # Initial run
        fetch_rates
        update_display
        ;;
esac