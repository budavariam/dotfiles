#!/usr/bin/env bash

TEXT_ITEM="notification.text"
# ICON_EMPTY="􀍕"
# ICON_EMPTY="􀀀"
ICON_EMPTY="􀣺"
ICON_ALERT="􀍜"
WHITE=0xaaffffff
RED=0xfff7768e
COLOR_RED="$RED"
COLOR_DEFAULT="$WHITE"

if [[ "$SENDER" == "mouse.clicked" ]]; then
    # Reset on click
    sketchybar --set "$TEXT_ITEM" icon="$ICON_EMPTY" icon.color="$COLOR_DEFAULT" label="" label.drawing=off background.drawing=off
elif [[ "$SENDER" == "notification_update" ]]; then
    # Update when event is triggered
    sketchybar --set "$TEXT_ITEM" icon="$ICON_ALERT" icon.color="$COLOR_RED" label="$VAR" label.drawing=on background.drawing=on
fi
