#!/usr/bin/env bash

COLOR="$WHITE"
cnf_aerospace=(
    display=active
    icon="􀢹"
    popup.height=20
    script="$PLUGIN_DIR/aerospace.sh"
    popup.align=center
    background.drawing=on
    background.padding_right="5"
    background.border_color="$COLOR"
    background.color="$BAR_COLOR"
    label.color="$COLOR"
    label.padding_right="$INNER_PADDINGS"
    icon.padding_left="$INNER_PADDINGS"
    icon.padding_right="6"
)

sketchybar --add event aerospace_workspace_change \
    --add item current_workspace right \
    --subscribe current_workspace aerospace_workspace_change mouse.clicked \
    --set current_workspace "${cnf_aerospace[@]}"
