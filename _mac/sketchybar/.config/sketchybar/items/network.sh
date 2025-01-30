#!/usr/bin/env bash

COLOR="$WHITE"

sketchybar --add item vpn_status right \
    --set vpn_status icon="􀞡" update_freq=30 background.drawing=off label.drawing=off script="$PLUGIN_DIR/vpn_status.sh" \
    --add item wifi_status right \
    --subscribe wifi_status wifi_change \
    --set wifi_status icon="􁣡" background.drawing=off label.drawing=off script="$PLUGIN_DIR/wifi_status.sh" \
    --add bracket b_network wifi_status vpn_status \
    --set b_network \
    icon.padding_left=10 \
    label.color="$COLOR" \
    label.padding_right=10 \
    background.corner_radius="$CORNER_RADIUS" \
    background.padding_right="$PADDINGS" \
    background.border_color="$WHITE" \
    background.drawing=on \
