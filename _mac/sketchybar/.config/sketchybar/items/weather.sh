#!/usr/bin/env bash

COLOR="$WHITE"

cnf_weather=(
      update_freq=600
      script="$PLUGIN_DIR/weather.sh"
      background.drawing=on
      background.border_color="$COLOR"
      background.color="$BAR_COLOR"
      label.color="$COLOR"
      padding_right=6
      padding_left=6
      label.padding_right="$INNER_PADDINGS"
      label.padding_left=0
      icon.padding_left="$INNER_PADDINGS"
      icon.padding_right="$INNER_PADDINGS"
)

sketchybar --add item weather left \
      --subscribe weather mouse.clicked system_woke \
      --set weather "${cnf_weather[@]}"