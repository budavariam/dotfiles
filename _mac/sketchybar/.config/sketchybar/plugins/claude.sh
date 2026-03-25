#!/usr/bin/env bash

ITEM="claude.status"
STATE_FILE="/tmp/claude-needs-action"

ORANGE=0xffff9e64
RED=0xfff7768e
WHITE=0xaaffffff

# Click clears the needs-action flag
if [[ "$SENDER" == "mouse.clicked" ]]; then
  echo 0 > "$STATE_FILE"
fi

# Count active Claude Code sessions by unique process group ID.
# pgrep -f matches every worker subprocess; one PGID == one session.
session_count=$(pgrep -f "claude-code" 2>/dev/null \
  | xargs ps -o pgid= -p 2>/dev/null \
  | tr -d ' ' | sort -u | grep -c '[0-9]' 2>/dev/null; true)

needs_action=0
[ "$(cat "$STATE_FILE" 2>/dev/null)" = "1" ] && needs_action=1

if [ "$session_count" = "0" ]; then
  echo 0 > "$STATE_FILE"
  /opt/homebrew/bin/sketchybar --set "$ITEM" drawing=off
  exit 0
fi

if [ "$needs_action" = "1" ]; then
  LABEL="${session_count}!"
  ICON_COLOR=$RED
  LABEL_COLOR=$RED
else
  LABEL="$session_count"
  ICON_COLOR=$ORANGE
  LABEL_COLOR=$WHITE
fi

/opt/homebrew/bin/sketchybar --set "$ITEM" \
  drawing=on \
  icon.color="$ICON_COLOR" \
  label="$LABEL" \
  label.color="$LABEL_COLOR" \
  label.drawing=on
