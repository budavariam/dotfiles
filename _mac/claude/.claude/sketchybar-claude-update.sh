#!/usr/bin/env bash
# Updates the SketchyBar claude status item from Claude Code hooks.
#
# Usage (called by hooks):
#   sketchybar-claude-update.sh set-needs-action   # waiting for user input
#   sketchybar-claude-update.sh clear-needs-action # claude is active again
#   sketchybar-claude-update.sh refresh            # just update session count
#
# Needs-action is tracked per session: one flag file per session id in FLAG_DIR,
# so the sketchybar dropdown can highlight which session is waiting.

input=$(cat)  # hooks pipe JSON on stdin; we only need session_id
session_id=$(printf '%s' "$input" | /opt/homebrew/bin/jq -r '.session_id // empty' 2>/dev/null)
session_id="${session_id:-unknown}"

SKETCHYBAR=/opt/homebrew/bin/sketchybar
FLAG_DIR="/tmp/claude-needs-action.d"
FLAG="$FLAG_DIR/$session_id"

case "${1:-refresh}" in
  set-needs-action)
    mkdir -p "$FLAG_DIR"
    : > "$FLAG"
    ;;
  clear-needs-action)
    # Only touch the filesystem if set, to avoid noisy I/O during every tool call
    [ -e "$FLAG" ] && rm -f "$FLAG"
    ;;
esac

"$SKETCHYBAR" --trigger claude_update 2>/dev/null || true
