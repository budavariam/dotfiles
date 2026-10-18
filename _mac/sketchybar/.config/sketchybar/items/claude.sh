#!/usr/bin/env bash

ITEM="claude.status"
EVENT_NAME="claude_update"

# nf-md-creation (U+F0674) - sparkles; Nerd Fonts has no Claude brand glyph.
# Alternatives: nf-md-robot $'\U000f06a9', plain star '✦' (U+2726)
ICON_CLAUDE=$'\U000f0674'

cnf_claude=(
  icon="$ICON_CLAUDE"
  icon.color="$ORANGE"
  label=""
  label.color="$WHITE"
  padding_left=6
  padding_right=6
  icon.padding_left="$INNER_PADDINGS"
  icon.padding_right="$INNER_PADDINGS"
  label.padding_left=0
  label.padding_right="$INNER_PADDINGS"
  background.drawing=on
  background.border_color="$WHITE"
  background.corner_radius="$CORNER_RADIUS"
  background.color="$BAR_COLOR"
  label.drawing=off
  drawing=off
  update_freq=30
  updates=on
  popup.align=left
  popup.background.color="$BAR_COLOR"
  popup.background.corner_radius="$CORNER_RADIUS"
  popup.y_offset=4
  script="$PLUGIN_DIR/claude.sh"
)

sketchybar --add item "$ITEM" left \
  --add event "$EVENT_NAME" \
  --subscribe "$ITEM" "$EVENT_NAME" mouse.clicked \
  --set "$ITEM" "${cnf_claude[@]}"
