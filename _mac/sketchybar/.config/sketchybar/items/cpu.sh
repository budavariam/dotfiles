#!/usr/bin/env bash

COLOR="$WHITE"

cnf_cpu=(
	background.padding_right=2
	background.padding_left=5
	icon="􀫥"
	icon.color="$COLOR"
	icon.padding_left="$INNER_PADDINGS"
	icon.padding_right="6"
	label.color="$COLOR"
	label.padding_right="$INNER_PADDINGS"
	background.corner_radius="$CORNER_RADIUS"
	background.border_color="$COLOR"
	background.color="$BAR_COLOR"
	label.drawing=off
	update_freq=5
	updates=when_shown
	associated_display=active
	background.drawing=on
	script="$PLUGIN_DIR/cpu.sh"
)

sketchybar --add item cpu right \
	--subscribe cpu mouse.entered mouse.exited \
	--set cpu "${cnf_cpu[@]}"
