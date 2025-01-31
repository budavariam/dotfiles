#!/usr/bin/env bash

VPN_NAME=$(scutil --nc list | grep Connected | awk -F'"' '{print $2}')

if [[ "$SENDER" == "mouse.entered" ]]; then
    sketchybar --set vpn_status label.drawing=on label="$VPN_NAME"
elif [[ "$SENDER" == "mouse.exited" ]]; then
    sketchybar --set vpn_status label.drawing=off
fi

if [ -n "$VPN_NAME" ]; then
    sketchybar --set vpn_status icon="􀞙"
else
    sketchybar --set vpn_status icon="􀞡"
fi
