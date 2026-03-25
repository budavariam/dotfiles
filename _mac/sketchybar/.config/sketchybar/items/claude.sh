#!/usr/bin/env bash

ITEM="claude.status"
EVENT_NAME="claude_update"

# ✦ U+2726 — 4-pointed star, close to Anthropic's star motif
ICON_CLAUDE="✦"

cnf_claude=(
  icon="$ICON_CLAUDE"
  icon.color="$ORANGE"
  label=""
  label.color="$WHITE"
  icon.padding_left="$INNER_PADDINGS"
  icon.padding_right=6
  label.padding_right="$INNER_PADDINGS"
  background.corner_radius="$CORNER_RADIUS"
  background.color="$BAR_COLOR"
  background.drawing=off
  label.drawing=off
  drawing=off
  update_freq=10
  script="$PLUGIN_DIR/claude.sh"
)

sketchybar --add item "$ITEM" left \
  --add event "$EVENT_NAME" \
  --subscribe "$ITEM" "$EVENT_NAME" mouse.clicked \
  --set "$ITEM" "${cnf_claude[@]}"
