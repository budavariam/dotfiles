#!/usr/bin/env bash
INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.notification_type // ""')
PAYLOAD_MSG=$(echo "$INPUT" | jq -r '.message // ""')

NEEDS_ACTION=0

case "$TYPE" in
  permission_prompt)
    TITLE="Claude Code - Permission Required"
    MSG="${PAYLOAD_MSG:-Claude needs your approval to continue}"
    NEEDS_ACTION=1
    ;;
  idle_prompt)
    TITLE="Claude Code - Waiting"
    MSG="${PAYLOAD_MSG:-Claude is waiting for your input}"
    ;;
  *)
    exit 0
    ;;
esac

LOGFILE="/tmp/claude-notify.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] TYPE=$TYPE TITLE=$TITLE MSG=$MSG" >> "$LOGFILE"

OUTPUT=$(terminal-notifier -title "$TITLE" -message "$MSG" -sound "Ping" -activate "com.googlecode.iterm2" 2>&1)
STATUS=$?
if [ $STATUS -ne 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: terminal-notifier exited with status $STATUS: $OUTPUT" >> "$LOGFILE"
fi

# Mark sketchybar item as needing user attention (only when action is required)
if [ "$NEEDS_ACTION" = "1" ]; then
  "$(dirname "$0")/sketchybar-claude-update.sh" set-needs-action 2>/dev/null || true
fi
