#!/usr/bin/env bash

WIFI_NAME=$(networksetup -getairportnetwork en0 | awk -F': ' '{print $2}' | xargs)

if [[ "$SENDER" == "mouse.entered" ]]; then
    sketchybar --set wifi_status label.drawing=on label="$WIFI_NAME"
elif [[ "$SENDER" == "mouse.exited" ]]; then
    sketchybar --set wifi_status label.drawing=off
fi

if [[ -z "$WIFI_NAME" || "$WIFI_NAME" == "Off" ]]; then
    sketchybar --set wifi_status icon="􁣡"
else
    sketchybar --set wifi_status icon="􀤆"
fi
