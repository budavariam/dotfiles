#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

if [[ "$(osascript -e 'application "Aerospace" is running')" != "true" ]]; then
  echo "Aerospace is not running"
  sketchybar --set "$NAME" label="" label.drawing=off popup.drawing=off
  exit 0
fi

COLOR_NORMAL_FOCUSED=0x55FF0000
COLOR_NUMBER_FOCUSED=0x99FF4444
COLOR_NORMAL=0x55000000
COLOR_NUMBER=0x55444444

POPUP_CORNER_RADIUS=5
GLOBAL_FOCUSED=$(aerospace list-workspaces --focused)

# Update every display's label.
# Cache files track the last-seen workspace per display so labels remain
# correct even when --visible is not supported by this AeroSpace version.
# Display 1 = main (built-in). Display 2 = secondary (Sidecar).
update_all_labels() {
    local CACHE="/tmp/aerospace_sketchybar"
    mkdir -p "$CACHE"

    local focused monitors main_mid focused_mid mid ws

    focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null | head -1)}"
    [ -z "$focused" ] && return

    monitors=$(aerospace list-monitors 2>/dev/null)
    [ -z "$monitors" ] && return

    # Identify main monitor by name — Built-in is always the MacBook screen
    main_mid=$(printf '%s\n' "$monitors" | grep -i "built-in" | awk '{print $1}' | head -1)
    # Fallback: anything that is not Sidecar/AirPlay
    [ -z "$main_mid" ] && \
        main_mid=$(printf '%s\n' "$monitors" | grep -iv "sidecar\|airplay" | awk '{print $1}' | head -1)

    # Find which aerospace monitor currently holds the focused workspace
    focused_mid=""
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        mid="${line%% *}"
        [ -z "$mid" ] && continue
        if aerospace list-workspaces --monitor "$mid" 2>/dev/null | grep -qFx "$focused"; then
            focused_mid="$mid"
            break
        fi
    done <<< "$monitors"

    # Write the focused workspace into the correct display cache
    if [ -n "$focused_mid" ]; then
        if [ "$focused_mid" = "$main_mid" ]; then
            echo "$focused" > "$CACHE/disp1"
        else
            echo "$focused" > "$CACHE/disp2"
        fi
    fi

    # Seed missing cache files on first run
    if [ ! -s "$CACHE/disp1" ] && [ -n "$main_mid" ]; then
        ws=$(aerospace list-workspaces --monitor "$main_mid" 2>/dev/null | head -1)
        [ -n "$ws" ] && echo "$ws" > "$CACHE/disp1"
    fi
    if [ ! -s "$CACHE/disp2" ]; then
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            mid="${line%% *}"
            [ -z "$mid" ] && continue
            [ "$mid" = "$main_mid" ] && continue
            ws=$(aerospace list-workspaces --monitor "$mid" 2>/dev/null | head -1)
            [ -n "$ws" ] && echo "$ws" > "$CACHE/disp2"
            break
        done <<< "$monitors"
    fi

    ws=$(cat "$CACHE/disp1" 2>/dev/null)
    [ -n "$ws" ] && sketchybar --set "current_workspace_1" label.drawing=on label="$ws" 2>/dev/null

    ws=$(cat "$CACHE/disp2" 2>/dev/null)
    [ -n "$ws" ] && sketchybar --set "current_workspace_2" label.drawing=on label="$ws" 2>/dev/null
}

update_popup_items() {
  items=()

  while IFS= read -r line; do
    items+=("$line")
  done < <(aerospace list-windows --all --format "%{workspace} | %{app-name} (%{window-title})                              |%{window-id}" | sort)

  sketchybar --remove "/space\.s_.*/"
  declare -i maxwidth=0
  declare -i width=0

  for i in "${!items[@]}"; do
    local label
    label="${items[$i]}"
    sid="${label%% *}"
    wid="${label##*|}"

    is_single_number=false
    if [[ "$sid" =~ ^[0-9]$ ]]; then
      is_single_number=true
    fi

    item_name="space.s_${sid}_${i}"
    label="${label%|*}"
    label="${label%"${label##*[! ]}"}"
    width=$((${#label} * 8 + 16))
    if [ "$width" -gt "$maxwidth" ]; then
      maxwidth=$width
    fi

    if [ "$sid" == "$GLOBAL_FOCUSED" ]; then
      if [ "$is_single_number" = true ]; then
        background_color="$COLOR_NUMBER_FOCUSED"
      else
        background_color="$COLOR_NORMAL_FOCUSED"
      fi
    else
      if [ "$is_single_number" = true ]; then
        background_color="$COLOR_NUMBER"
      else
        background_color="$COLOR_NORMAL"
      fi
    fi

    sketchybar \
        --add item "$item_name" "popup.$NAME" \
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
            sketchybar --set $NAME label=\"$sid\" popup.drawing=off \
          "
  done
  [ "${#items[@]}" -gt 0 ] && sketchybar --set "/space\.s_.*/" width="$maxwidth"
}

mouse_clicked() {
  PREV_POPUP_STATE=$(sketchybar --query "$NAME" | jq -r '.popup.drawing')
  if [[ "$NAME" =~ current_workspace && ( "$PREV_POPUP_STATE" == "off" || "$PREV_POPUP_STATE" == "null" ) ]]; then
    update_popup_items
  fi
  sketchybar --set "$NAME" popup.drawing=toggle
}

case "$SENDER" in
  "mouse.clicked" | "toggle_aerospace_popup") mouse_clicked ;;
  *) update_all_labels ;;
esac
