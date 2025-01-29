#!/usr/bin/env bash

WIFI_NAME=$(networksetup -getairportnetwork en0 | awk -F': ' '{print $2}' | xargs)

if [[ -z "$WIFI_NAME" || "$WIFI_NAME" == "Off" ]]; then
    sketchybar --set wifi_status icon="􁣡"
else
    sketchybar --set wifi_status icon="􀤆"
fi
