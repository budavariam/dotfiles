#!/usr/bin/env bash

ITEM="ai.status"
EVENT_NAME="ai_update"
HOOK_EVENT_NAME="claude_update"  # triggered by ~/.claude/sketchybar-claude-update.sh

# nf-md-creation (U+F0674) - sparkles, written as UTF-8 bytes: bash 3.2 (no shebang here) has no \U escape; Nerd Fonts has no brand glyph for these tools.
# Alternatives: nf-md-robot $'\U000f06a9', plain star '✦' (U+2726)
ICON_AI=$'\xf3\xb0\x99\xb4'

cnf_ai=(
  icon="$ICON_AI"
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
  script="$PLUGIN_DIR/ai.sh"
)

sketchybar --add item "$ITEM" left \
  --add event "$EVENT_NAME" \
  --add event "$HOOK_EVENT_NAME" \
  --subscribe "$ITEM" "$EVENT_NAME" "$HOOK_EVENT_NAME" mouse.clicked \
  --set "$ITEM" "${cnf_ai[@]}"
