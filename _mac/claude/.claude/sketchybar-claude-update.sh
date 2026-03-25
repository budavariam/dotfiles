#!/usr/bin/env bash
# Updates the SketchyBar claude status item from Claude Code hooks.
#
# Usage (called by hooks):
#   sketchybar-claude-update.sh set-needs-action   # waiting for user input
#   sketchybar-claude-update.sh clear-needs-action # claude is active again
#   sketchybar-claude-update.sh refresh            # just update session count

# Discard stdin (hooks always pipe JSON; we don't need it here)
cat > /dev/null

SKETCHYBAR=/opt/homebrew/bin/sketchybar
STATE_FILE="/tmp/claude-needs-action"

case "${1:-refresh}" in
  set-needs-action)
    echo 1 > "$STATE_FILE"
    ;;
  clear-needs-action)
    # Only write if currently set, to avoid noisy I/O during every tool call
    if [ "$(cat "$STATE_FILE" 2>/dev/null)" = "1" ]; then
      echo 0 > "$STATE_FILE"
    fi
    ;;
esac

"$SKETCHYBAR" --trigger claude_update 2>/dev/null || true
