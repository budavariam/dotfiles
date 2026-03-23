#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$DIR/settings.json"
STATUSLINE_CMD="bash $DIR/statusline-command.sh"

if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

# Set statusLine (idempotent)
UPDATED=$(jq --arg cmd "$STATUSLINE_CMD" '
  if .statusLine.command == $cmd
  then .
  else .statusLine = {"type": "command", "command": $cmd}
  end
' "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"

echo "statusLine configured in $SETTINGS"
