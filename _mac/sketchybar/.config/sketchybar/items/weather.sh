#!/usr/bin/env bash

COLOR="$WHITE"

sketchybar --add item weather left \
      --set weather \
            update_freq=600 \
            script="$PLUGIN_DIR/weather.sh" \
            background.drawing=on \
            background.border_color="$COLOR" \
            background.color="$BAR_COLOR" \
            label.color="$COLOR" \
            label.padding_right="$INNER_PADDINGS" \
            icon.padding_left="$INNER_PADDINGS"