#!/bin/bash

if [[ "$SENDER" == "mouse.clicked" ]]; then
    open "https://www.mnb.hu/arfolyamok"
    exit 0
fi

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
GREEN=0xaa28a745
RED=0xaadc3545
ERROR_COLOR=0xaadc3545
FADE_HOURS=3  # Number of hours before color completely fades to white

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to cleanup old cache files (keep only last 7 days)
cleanup_cache() {
    find "$CACHE_DIR" -name "rates_*.json" -mtime +7 -delete
}

# Function to fetch exchange rates
fetch_rates() {
    if [ -f "$CACHE_FILE" ]; then
        return 0
    fi
    # Using exchangerate-api.com's v6 API
    response=$(curl -s "https://v6.exchangerate-api.com/v6/${API_KEY_EXCHANGE_RATE}/latest/HUF")
 
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        # Save current rates to cache
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

# Function to interpolate color based on time elapsed
interpolate_color() {
    local base_color=$1
    local elapsed_hours=$2
    
    if [ $elapsed_hours -ge $FADE_HOURS ]; then
        echo "$WHITE"
        return
    fi
    
    # Extract RGB components
    local base_r=$((0x${base_color:4:2}))
    local base_g=$((0x${base_color:6:2}))
    local base_b=$((0x${base_color:8:2}))
    local white_r=$((0xff))
    local white_g=$((0xff))
    local white_b=$((0xff))
    
    # Calculate fade factor (0 to 1)
    local fade=$(echo "scale=4; $elapsed_hours / $FADE_HOURS" | bc)
    
    # Interpolate each color component
    local new_r=$(echo "scale=0; (($white_r - $base_r) * $fade + $base_r)/1" | bc)
    local new_g=$(echo "scale=0; (($white_g - $base_g) * $fade + $base_g)/1" | bc)
    local new_b=$(echo "scale=0; (($white_b - $base_b) * $fade + $base_b)/1" | bc)
    
    # Format the new color
    printf "0xaa%02x%02x%02x" $new_r $new_g $new_b
}

# Function to determine color based on rate movement
get_color() {
    local current=$1
    local previous=$2
    local cache_file=$3
    local fetch_timestamp=$(stat -f %m "$cache_file")
    local current_timestamp=$(date +%s)
    local elapsed_hours=$(( (current_timestamp - fetch_timestamp) / 3600 ))
    # echo "$cache_file $fetch_timestamp $current_timestamp $elapsed_hours" >> /tmp/.debug_sketchbar
    if [ -z "$previous" ] || [ "$current" = "$previous" ]; then
        echo "$WHITE"
    elif (($(echo "$current > $previous" | bc -l))); then
        interpolate_color "$RED" "$elapsed_hours"
    else
        interpolate_color "$GREEN" "$elapsed_hours"
    fi
}

# Function to update the display
update_display() {
    local current_date, current_cache, previous_date, previous_cache
    current_date=$(date +%Y%m%d)
    current_cache="$CACHE_DIR/rates_$current_date.json"
    previous_date=$(date -v-1d +%Y%m%d)
    previous_cache="$CACHE_DIR/rates_$previous_date.json"

    # Fetch new rates if today's cache doesn't exist
    if [ ! -f "$current_cache" ]; then
        fetch_rates
    fi

    # Read current and previous rates
    if [ -f "$current_cache" ]; then
        EUR_RATE=$(calculate_huf_rate "$(jq -r '.conversion_rates.EUR' "$current_cache")")
        USD_RATE=$(calculate_huf_rate "$(jq -r '.conversion_rates.USD' "$current_cache")")
        GBP_RATE=$(calculate_huf_rate "$(jq -r '.conversion_rates.GBP' "$current_cache")")
        # TIMESTAMP=$(date -r "$current_cache" "+%H:%M")

        if [ -f "$previous_cache" ]; then
            PREV_EUR_RATE=$(calculate_huf_rate "$(jq -r '.conversion_rates.EUR' "$previous_cache")")
            PREV_USD_RATE=$(calculate_huf_rate "$(jq -r '.conversion_rates.USD' "$previous_cache")")
            PREV_GBP_RATE=$(calculate_huf_rate "$(jq -r '.conversion_rates.GBP' "$previous_cache")")

            EUR_COLOR=$(get_color "$EUR_RATE" "$PREV_EUR_RATE" "$current_cache")
            USD_COLOR=$(get_color "$USD_RATE" "$PREV_USD_RATE" "$current_cache")
            GBP_COLOR=$(get_color "$GBP_RATE" "$PREV_GBP_RATE" "$current_cache")
        else
            EUR_COLOR="$WHITE"
            USD_COLOR="$WHITE"
            GBP_COLOR="$WHITE"
        fi

        sketchybar -m \
            --set currency_euro \
                label="${EUR_RATE%.*}" \
                icon.color="$EUR_COLOR" \
            --set currency_usd \
                label="${USD_RATE%.*}" \
                icon.color="$USD_COLOR" \
            --set currency_gbp \
                label="${GBP_RATE%.*}" \
                icon.color="$GBP_COLOR" \
            --set currency_item \
                label.drawing=off \
                icon.drawing=off
    else
        sketchybar -m --set currency_item \
            label="Failed to fetch rates" \
            label.color="$ERROR_COLOR" \
            label.drawing=on \
            icon.drawing=on
    fi
}

test_colors() {
    TEST_UNTIL=8

    hex_to_ansi() {
        # Function to convert hex color to ANSI escape sequence
        local hex=$1
        local r=$((0x${hex:4:2}))
        local g=$((0x${hex:6:2}))
        local b=$((0x${hex:8:2}))
        echo -e "\e[38;2;${r};${g};${b}m"
    }

    RESET='\033[0m'

    test_color() {
        echo "Testing $1 to WHITE transition:"
        echo "Hour | Color Hex  | Sample Text"
        echo "-----------------------------------"
        for hour in $(seq 0 "$TEST_UNTIL"); do
            color=$(interpolate_color "$2" "$hour")
            ansi=$(hex_to_ansi "$color")
            printf "%-4d | %s | %s999 Sample Text${RESET}\n" "$hour" "$color" "$ansi"
        done
    }

    test_color "RED" "$RED" 
    test_color "GREEN" "$GREEN" 
}

# Handle different execution modes
case "$1" in
--update)
    update_display
    ;;
--test)
    test_colors
    ;;
*)
    # Initial run
    fetch_rates
    update_display
    ;;
esac
