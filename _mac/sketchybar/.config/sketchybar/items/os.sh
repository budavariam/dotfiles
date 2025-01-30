#!/usr/bin/env bash

COLOR="$WHITE"

sketchybar \
    --add item battery right \
    --add item focus_status right \
    --add item keyboard right \
    --add item volume right \
    --set volume script="$PLUGIN_DIR/volume.sh" \
    --subscribe volume volume_change \
    --set battery update_freq=120 script="$PLUGIN_DIR/battery.sh" \
    --subscribe battery system_woke power_source_change \
    --add event focus_mode_on "_NSDoNotDisturbEnabledNotification" \
    --add event focus_mode_off "_NSDoNotDisturbDisabledNotification" \
    --subscribe focus_status focus_mode_on focus_mode_off \
    --set focus_status icon="󰸘" label.drawing=off script="$PLUGIN_DIR/focus_status.sh" \
    --add event input_source_changed "AppleSelectedInputSourcesChangedNotification" \
    --set keyboard label.drawing=off script="$PLUGIN_DIR/keyboard.sh" \
    --subscribe keyboard input_source_changed \
    --add bracket b_os battery volume focus_status keyboard \
    --set b_os \
        icon.padding_left=10 \
        label.color="$COLOR" \
        label.padding_right=10 \
        background.drawing=on \
        background.corner_radius="$CORNER_RADIUS" \
        background.padding_right=5 \
        background.border_color="$WHITE" \
        background.color="$BAR_COLOR" \
        background.padding_left=5