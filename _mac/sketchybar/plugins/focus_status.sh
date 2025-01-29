#!/usr/bin/env bash

FOCUS_MODE=$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes" 2>/dev/null)

if [[ "$FOCUS_MODE" == "1" ]]; then
    sketchybar --set focus_status icon="􀆺" icon.color=0xFFFFFFFF
else
    sketchybar --set focus_status icon="􀆹" icon.color=0xFF888888
fi