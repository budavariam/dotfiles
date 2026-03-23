#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$DIR/settings.json"
NOTIFY_SH="$DIR/notify.sh"
ASK_CMD=$'MSG=$(jq -r \'.tool_input.questions[0].question // "Claude needs your input"\'); terminal-notifier -title "Claude Code - Question" -message "Claude is asking: $MSG" -sound "Ping" -activate "com.googlecode.iterm2"'

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

# Add PostToolUse AskUserQuestion hook (idempotent)
UPDATED=$(jq --arg cmd "$ASK_CMD" '
  if (.hooks.PostToolUse // []) | map(select(.matcher == "AskUserQuestion")) | length > 0
  then .
  else .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $cmd}]}])
  end
' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"

echo "Notification hooks configured in $SETTINGS"
