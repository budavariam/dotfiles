#!/bin/sh

LAYOUT_NAME=$(
    defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | # get input layouts
        grep "KeyboardLayout Name" | # filter the relevant part
        awk -F' = ' '{print $2}' | # extract the name from the equal sign
        tr -d ';' | # remove semicolon
        tr -d "\"" # remove quotes
)

case "$LAYOUT_NAME" in
    *Hungarian*) FLAG="🇭🇺" ;;
    *) FLAG="🇺🇸" ;;
esac

# sketchybar --set keyboard label="$FLAG $LAYOUT_NAME"
sketchybar --set keyboard icon="$FLAG"
