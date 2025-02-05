#!/usr/bin/env bash

COLOR="$WHITE"

sketchybar --add event aerospace_workspace_change \
    --add item current_workspace left \
    --subscribe current_workspace aerospace_workspace_change \
    --set current_workspace \
        display=active \
        icon="􀢹" \
        popup.height=20 \
        script="$PLUGIN_DIR/aerospace.sh" \
        click_script="sketchybar --set current_workspace popup.drawing=toggle" \
        popup.align=center \
        background.drawing=on \
        background.padding_right="$PADDINGS" \
        background.border_color="$COLOR" \
        background.color="$BAR_COLOR" \
        label.color="$COLOR" \
        label.padding_right="$INNER_PADDINGS" \
        icon.padding_left="$INNER_PADDINGS" \
        icon.padding_right="6"

for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item space.s_$sid popup.current_workspace \
        --set space.s_$sid \
        label="$sid" \
        background.padding_left=1 \
        background.padding_right=0 \
        background.color="$POPUP_HIGHLIGHT_COLOR" \
        background.drawing=on \
        background.corner_radius="$POPUP_CORNER_RADIUS" \
        width=35 \
        click_script="aerospace workspace $sid && sketchybar --set current_workspace label=\"$sid\" && sketchybar --set current_workspace popup.drawing=off"
done
