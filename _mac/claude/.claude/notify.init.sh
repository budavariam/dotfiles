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

# Add PreToolUse AskUserQuestion hook: notify + flag the session before the question is shown (idempotent).
# Also migrates the old PostToolUse variant, which fired after the answer.
UPDATED=$(jq --arg cmd "$ASK_CMD" '
  .hooks.PostToolUse = ((.hooks.PostToolUse // []) | map(select(.matcher != "AskUserQuestion")))
  | if (.hooks.PreToolUse // []) | map(select(.matcher == "AskUserQuestion" and (.hooks[]?.command | contains("sketchybar-claude-update.sh")))) | length > 0
  then .
  else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $cmd}]}])
  end
' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"

# Add PostToolUse hook: clear needs-action once the tool ran (question answered / permission granted).
# Not PreToolUse: that would clear the flag the AskUserQuestion hook just set.
CLEAR_CMD="$SKETCHYBAR_SH clear-needs-action"
UPDATED=$(jq --arg cmd "$CLEAR_CMD" '
  .hooks.PreToolUse = ((.hooks.PreToolUse // []) | map(select(any(.hooks[]?; .command == $cmd) | not)))
  | if (.hooks.PostToolUse // []) | map(select(.hooks[]?.command == $cmd)) | length > 0
  then .
  else .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [{"hooks": [{"type": "command", "command": $cmd}]}])
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
echo ""
echo "NOTE: If running inside tmux, terminal-notifier requires reattach-to-user-namespace to reach"
echo "the macOS Notification Center. Ensure your tmux config contains:"
echo "  set-option -g default-command \"which reattach-to-user-namespace > /dev/null && reattach-to-user-namespace -l \$SHELL || \$SHELL\""
echo "Install it with: brew install reattach-to-user-namespace"
