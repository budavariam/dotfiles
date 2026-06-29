#!/usr/bin/env bash

COLOR="$WHITE"
cnf_aerospace=(
    updates=on
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
    --add event toggle_aerospace_popup

# One item per physical display; sketchybar display 1 = main, 2..N = others
N_MONITORS=$(aerospace list-monitors 2>/dev/null | grep -c '.')
[ "${N_MONITORS:-0}" -eq 0 ] && N_MONITORS=1

for i in $(seq 1 "$N_MONITORS"); do
    sketchybar --add item "current_workspace_$i" right \
        --set "current_workspace_$i" associated_display=$i "${cnf_aerospace[@]}" \
        --subscribe "current_workspace_$i" aerospace_workspace_change mouse.clicked toggle_aerospace_popup
done
