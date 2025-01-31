#!/usr/bin/env bash

FOCUS_IS_ON=false

if [[ "$SENDER" == "focus_mode_on" ]]; then
    FOCUS_IS_ON=true
elif [[ "$SENDER" == "focus_mode_off" ]]; then
    FOCUS_IS_ON=false
elif [[ "$SENDER" == "forced" ]]; then
    FOCUS_MODE=$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes" 2>/dev/null)
    if [[ "$FOCUS_MODE" == "1" ]]; then
        FOCUS_IS_ON=true
    fi
fi

if [[ "$FOCUS_IS_ON" == true ]]; then
    sketchybar --set focus_status icon="􀆺" icon.color=0xff5e5ce6
else
    sketchybar --set focus_status icon="􀆹" icon.color=0xFF888888
fi
