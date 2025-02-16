#!/usr/bin/env bash

COLOR="$WHITE"

cnf_vpn=(
    icon="􀞡"
    update_freq=30
    background.drawing=off
    label.drawing=off
    script="$PLUGIN_DIR/vpn_status.sh"
)
cnf_wifi=(
    icon="􁣡"
    background.drawing=off
    label.drawing=off
    script="$PLUGIN_DIR/wifi_status.sh"
)
cnf_bracket=(
    icon.padding_left=10
    label.color="$COLOR"
    label.padding_right=10
    background.corner_radius="$CORNER_RADIUS"
    background.padding_right="$PADDINGS"
    background.border_color="$WHITE"
    background.drawing=on
)

sketchybar --add item vpn_status right \
    --set vpn_status "${cnf_vpn[@]}" \
    --subscribe vpn_status mouse.entered mouse.exited \
    --add item wifi_status right \
    --subscribe wifi_status wifi_change mouse.entered mouse.exited \
    --set wifi_status "${cnf_wifi[@]}" \
    --add bracket b_network wifi_status vpn_status \
    --set b_network "${cnf_bracket[@]}"
