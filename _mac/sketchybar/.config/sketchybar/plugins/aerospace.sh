#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh
DIALOG_SCRIPT="$CONFIG_DIR/plugins/aerospace_ws.scpt"

if [[ "$(osascript -e 'application "Aerospace" is running')" != "true" ]]; then
  echo "Aerospace is not running"
  sketchybar --set current_workspace label="" label.drawing=off
  exit 0
fi

# Update the label of the main workspace indicator
if [ -z "$FOCUSED_WORKSPACE" ]; then
  # NOTE: on first start it can be empty, get it from aerospace
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
  sketchybar --set current_workspace label.drawing=on label="$FOCUSED_WORKSPACE"
else
  sketchybar --set current_workspace label.drawing=on label="$FOCUSED_WORKSPACE"
fi

# Reset the bgcolor for all subitems with regex, and set the color of the curent selected
sketchybar --set "/space\.s_.*/" background.color=0x55000000
sketchybar --set "space.s_$FOCUSED_WORKSPACE" background.color=0x55FF0000

mouse_clicked() {
  # NOTE: turn off sketchybar toggle for now
  # sketchybar --set current_workspace popup.drawing=toggle
  PREV_POPUP_STATE=$(sketchybar --query current_workspace | jq -r '.popup.drawing' )
  if [ "$PREV_POPUP_STATE" == "off" ]; then
    osascript "$DIALOG_SCRIPT"
  fi
}

case "$SENDER" in
"mouse.clicked") mouse_clicked ;;
*) update ;;
esac
