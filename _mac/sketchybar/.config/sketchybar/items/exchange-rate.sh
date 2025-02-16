#!/usr/bin/env bash

COLOR="$WHITE"

sketchybar --add item currency_item left \
           --set currency_item \
                update_freq=86400 \
	            script="$PLUGIN_DIR/exchange-rate.sh" \
                icon="" \
                icon.color="$COLOR" \
                icon.padding_left="$INNER_PADDINGS" \
                icon.padding_right="6" \
                label.color="$COLOR" \
                label.padding_right="$INNER_PADDINGS" \
                background.corner_radius="$CORNER_RADIUS" \
                background.border_color="$COLOR" \
                background.color="$BAR_COLOR" \
                associated_display=active \
                background.drawing="on"