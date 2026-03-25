#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$DIR/settings.json"
NOTIFY_SH="$DIR/notify.sh"
SKETCHYBAR_SH="$DIR/sketchybar-claude-update.sh"
ASK_CMD=$'MSG=$(jq -r \'.tool_input.questions[0].question // "Claude needs your input"\'); terminal-notifier -title "Claude Code - Question" -message "Claude is asking: $MSG" -sound "Ping" -activate "com.googlecode.iterm2"'
ASK_CMD="$ASK_CMD; $SKETCHYBAR_SH set-needs-action"

if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

# Add Notification hook (idempotent)
UPDATED=$(jq --arg cmd "$NOTIFY_SH" '
  if (.hooks.Notification // []) | map(select(.hooks[]?.command == $cmd)) | length > 0
  then .
  else .hooks.Notification = ((.hooks.Notification // []) + [{"hooks": [{"type": "command", "command": $cmd}]}])
  end
' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"

# Add PostToolUse AskUserQuestion hook (idempotent — keyed on sketchybar call presence)
UPDATED=$(jq --arg cmd "$ASK_CMD" '
  if (.hooks.PostToolUse // []) | map(select(.matcher == "AskUserQuestion" and (.hooks[]?.command | contains("sketchybar-claude-update.sh")))) | length > 0
  then .
  else .hooks.PostToolUse = (
    ((.hooks.PostToolUse // []) | map(select(.matcher != "AskUserQuestion")))
    + [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $cmd}]}]
  )
  end
' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"

# Add PreToolUse hook: clear needs-action flag when Claude is working (user responded)
CLEAR_CMD="$SKETCHYBAR_SH clear-needs-action"
UPDATED=$(jq --arg cmd "$CLEAR_CMD" '
  if (.hooks.PreToolUse // []) | map(select(.hooks[]?.command == $cmd)) | length > 0
  then .
  else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{"hooks": [{"type": "command", "command": $cmd}]}])
  end
' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"

# Add Stop hooks: clear needs-action and refresh session count when a session ends
CLEAR_ON_STOP_CMD="$SKETCHYBAR_SH clear-needs-action"
REFRESH_CMD="$SKETCHYBAR_SH refresh"
UPDATED=$(jq --arg clear "$CLEAR_ON_STOP_CMD" --arg refresh "$REFRESH_CMD" '
  if (.hooks.Stop // []) | map(select(.hooks[]?.command == $refresh)) | length > 0
  then .
  else .hooks.Stop = ((.hooks.Stop // []) + [{"hooks": [
    {"type": "command", "command": $clear},
    {"type": "command", "command": $refresh}
  ]}])
  end
' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"

echo "Notification hooks configured in $SETTINGS"
