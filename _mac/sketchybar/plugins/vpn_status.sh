#!/usr/bin/env bash

VPN_NAME=$(scutil --nc list | grep Connected | awk -F'"' '{print $2}')

if [ -n "$VPN_NAME" ]; then
    sketchybar --set vpn_status icon="􀞙"
else
    sketchybar --set vpn_status icon="􀞡"
fi
