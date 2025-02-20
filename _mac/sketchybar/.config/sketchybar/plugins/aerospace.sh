#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

if [[ "$(osascript -e 'application "Aerospace" is running')" != "true" ]]; then
  echo "Aerospace is not running"
  sketchybar --set current_workspace label="" label.drawing=off
  exit 0
fi

FOCUSED_WORKSPACE_COLOR=0x55FF0000
POPUP_CORNER_RADIUS=5
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)

update_label() {
  # Update the label of the main workspace indicator
  if [ -z "$FOCUSED_WORKSPACE" ]; then
    # NOTE: on first start it can be empty, get it from aerospace
    sketchybar --set current_workspace label.drawing=on label="$FOCUSED_WORKSPACE"
  else
    sketchybar --set current_workspace label.drawing=on label="$FOCUSED_WORKSPACE"
  fi
}


update_popup_items() {
  items=()

  # Get the list of windows from aerospace
  while IFS= read -r line; do
    items+=("$line")
  done < <(aerospace list-windows --all --format "%{workspace} | %{app-name} (%{window-title})                              |%{window-id}" | sort)
  # echo "${items[*]}" >> /tmp/.debug_sketchbar


  # Reset the bgcolor for all subitems with regex, and set the color of the curent selected
  sketchybar --remove "/space\.s_.*/"
  declare -i maxwidth=0
  declare -i width=0
  # Refresh items
  for i in "${!items[@]}"; do
    local label
    label="${items[$i]}"
    sid="${label%% *}"          # Get first word (before first space)
    wid="${label##*|}"          # Get text after last pipe
    item_name="space.s_${sid}_${i}"
    label="${label:0:30}"       # Truncate to 30 chars
    # echo "${items[$i]} ------ $wid" >> /tmp/.debug_sketchbar
    # echo "item: $sid" >> /tmp/.debug_sketchbar
    width=$((${#label} * 8 + 8))
    if [ "$width" -gt "$maxwidth" ]; then
        maxwidth=$width
    fi
    background_color=0x55000000 
    if [ "$sid" == "$FOCUSED_WORKSPACE" ]; then
      background_color="$FOCUSED_WORKSPACE_COLOR"
    fi
    # echo "'aerospace focus --window-id $wid' '$sid'" >> /tmp/.debug_sketchbar

    sketchybar \
        --add item "$item_name" popup.current_workspace \
        --set "$item_name" \
          label="$label" \
          background.color="$background_color" \
          background.padding_left=1 \
          background.padding_right=0 \
          background.drawing=on \
          background.corner_radius="$POPUP_CORNER_RADIUS" \
          click_script="\
            aerospace workspace \"$sid\"; \
            aerospace focus --window-id \"$wid\"; \
            sketchybar --set current_workspace label=\"$sid\" popup.drawing=off \
          "
  done
  sketchybar --set "/space\.s_.*/" width="$maxwidth"
}

mouse_clicked() {
  PREV_POPUP_STATE=$(sketchybar --query current_workspace | jq -r '.popup.drawing')
  if [[ "$NAME" == "current_workspace" && ( "$PREV_POPUP_STATE" == "off" || "$PREV_POPUP_STATE" == "null" ) ]]; then
    update_popup_items
  fi
  sketchybar --set current_workspace popup.drawing=toggle
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  *) update_label ;;
esac
