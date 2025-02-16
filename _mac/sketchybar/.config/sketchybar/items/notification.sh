#!/usr/bin/env bash

# Define variables
TEXT_ITEM="notification.text"
ICON_EMPTY="􀣺"
ICON_ALERT="􀍜"
EVENT_NAME="notification_update"

cnf_notification=(
	icon="$ICON_EMPTY"
	icon.color="$WHITE"
	label.color="$WHITE"
	icon.padding_left="$INNER_PADDINGS"
	icon.padding_right="6"
	background.padding_right="$PADDINGS"
	label.padding_right="$INNER_PADDINGS"
	background.corner_radius="$CORNER_RADIUS"
	background.border_color="$WHITE"
	background.color="$BAR_COLOR"
	label.drawing=off
	background.drawing=on
	script="$PLUGIN_DIR/notification.sh"
)

sketchybar --add item "$TEXT_ITEM" left \
	--add event "$EVENT_NAME" \
	--subscribe "$TEXT_ITEM" "$EVENT_NAME" mouse.clicked \
	--set "$TEXT_ITEM" "${cnf_notification[@]}"