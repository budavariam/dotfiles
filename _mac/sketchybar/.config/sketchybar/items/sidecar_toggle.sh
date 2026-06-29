#!/usr/bin/env bash

# Show correct initial icon based on current config state
if grep -q "monitor.'sidecar' = 32" "$HOME/.aerospace.toml" 2>/dev/null; then
    INITIAL_ICON="▣"  # gap is on
else
    INITIAL_ICON="□"  # gap is off
fi

sketchybar --add item sidecar_toggle right \
    --set sidecar_toggle \
        associated_display=2 \
        icon="$INITIAL_ICON" \
        label.drawing=off \
        script="$PLUGIN_DIR/sidecar_toggle.sh" \
        background.drawing=on \
        background.color="$BAR_COLOR" \
        background.border_color="$WHITE" \
        background.padding_right="5" \
        icon.padding_left="$INNER_PADDINGS" \
        icon.padding_right="$INNER_PADDINGS" \
    --subscribe sidecar_toggle mouse.clicked
