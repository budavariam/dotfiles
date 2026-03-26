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

# Count active Claude Code sessions via ~/.claude/sessions/ (one JSON file per session).
session_count=0
for f in ~/.claude/sessions/*.json; do
  [ -f "$f" ] || continue
  pid=$(python3 -c "import json; print(json.load(open('$f'))['pid'])" 2>/dev/null)
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && session_count=$((session_count + 1))
done

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
