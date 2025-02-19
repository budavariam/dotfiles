#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh
# DIALOG_SCRIPT="$CONFIG_DIR/plugins/aerospace_ws.scpt"

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


update_popup_items() {
  items=()

  # Get the list of windows from aerospace
  while IFS= read -r line; do
    items+=("$line")
  done < <(aerospace list-windows --all --format "%{workspace} | %{app-name} (%{window-title})" | cut -c 1-30 | sort)
  # echo "${items[*]}" >> /tmp/.debug_sketchbar


  # Reset the bgcolor for all subitems with regex, and set the color of the curent selected
  sketchybar \
    --set "/space\.s_.*/" background.color=0x55000000 drawing=off \
    --set "space.s_$FOCUSED_WORKSPACE" background.color=0x55FF0000

  # Refresh items
  for i in "${!items[@]}"; do
    local label="${items[$i]}"
    workspace_name=$(echo "$label" | cut -d' ' -f1)
    item_name="space.s_$workspace_name"
    # echo "item: $workspace_name" >> /tmp/.debug_sketchbar
    width=$(((${#label} + 1) * 8))
    sketchybar --set "$item_name" label="$label" drawing=on width=$width
  done
}

mouse_clicked() {
  PREV_POPUP_STATE=$(sketchybar --query current_workspace | jq -r '.popup.drawing')
  if [[ "$NAME" == "current_workspace" && "$PREV_POPUP_STATE" == "off" ]]; then
    update_popup_items
  fi
  sketchybar --set current_workspace popup.drawing=toggle
  # if [ "$PREV_POPUP_STATE" == "off" ]; then
  #   osascript "$DIALOG_SCRIPT"
  # fi
}

case "$SENDER" in
"mouse.clicked") mouse_clicked ;;
*) : ;;
esac
