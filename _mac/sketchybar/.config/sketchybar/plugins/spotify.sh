#!/usr/bin/env bash

if [[ "$(osascript -e 'application "Spotify" is running')" != "true" ]]; then
  echo "Spotify is not running"
  sketchybar --set spotify.name label="" label.drawing=off popup.drawing="off"
  exit 0
fi

next() {
  osascript -e 'tell application "Spotify" to play next track'
}

back() {
  osascript -e 'tell application "Spotify" to play previous track'
}

play() {
  osascript -e 'tell application "Spotify" to playpause'
}

repeat() {
  local repeat
  repeat=$(osascript -e 'tell application "Spotify" to get repeating')

  if [[ "$repeat" == "false" ]]; then
    sketchybar -m --set spotify.repeat icon.highlight=on
    osascript -e 'tell application "Spotify" to set repeating to true'
  else
    sketchybar -m --set spotify.repeat icon.highlight=off
    osascript -e 'tell application "Spotify" to set repeating to false'
  fi
}

shuffle() {
  local shuffle
  shuffle=$(osascript -e 'tell application "Spotify" to get shuffling')

  if [[ "$shuffle" == "false" ]]; then
    sketchybar -m --set spotify.shuffle icon.highlight=on
    osascript -e 'tell application "Spotify" to set shuffling to true'
  else
    sketchybar -m --set spotify.shuffle icon.highlight=off
    osascript -e 'tell application "Spotify" to set shuffling to false'
  fi
}

update() {
    local PLAYING=1
    local TRACK=""
    local ARTIST=""
    local ALBUM=""
    local SHUFFLE=""
    local REPEAT=""

    # Check if Spotify is playing
    if [ "$(echo "$INFO" | jq -r '.["Player State"]')" = "Playing" ]; then
        PLAYING=0
        
        # Extract metadata and trim to 20 characters
        TRACK="$(echo "$INFO" | jq -r '.Name' | cut -c1-20)"
        ARTIST="$(echo "$INFO" | jq -r '.Artist' | cut -c1-20)"
        ALBUM="$(echo "$INFO" | jq -r '.Album' | cut -c1-20)"
        
        # Get Spotify shuffle and repeat status
        SHUFFLE="$(osascript -e 'tell application "Spotify" to get shuffling')"
        REPEAT="$(osascript -e 'tell application "Spotify" to get repeating')"
    fi
    
    # Build the argument array
    local -a args=()
    
    if [ "$PLAYING" -eq 0 ]; then
        # If playing, set appropriate labels and icons
        if [ -z "$ARTIST" ]; then
            args+=("--set" "spotify.name" "label=$TRACK 􀉮 $ALBUM" "label.drawing=on")
        else
            args+=("--set" "spotify.name" "label=$TRACK 􀉮 $ARTIST" "label.drawing=on")
        fi
        
        args+=(
            "--set" "spotify.play" "icon=􀊆"
            "--set" "spotify.shuffle" "icon.highlight=$SHUFFLE"
            "--set" "spotify.repeat" "icon.highlight=$REPEAT"
        )
    else
        # If not playing, set default state
        args+=(
            # "--set" "spotify" "drawing=off"
            "--set" "spotify.name" "popup.drawing=off"
            "--set" "spotify.play" "icon=􀊄"
        )
    fi
    
    # echo "$SENDER $NAME $INFO $PLAYING $ARTIST $TRACK $ALBUM" >> /tmp/.debug_sketchbar
    # Execute sketchybar command with all arguments
    sketchybar -m "${args[@]}"
}

toggle() {
    sketchybar -m --set spotify.name popup.drawing=toggle
}

popup() {
  sketchybar --set spotify.name popup.drawing="$1"
}

get_info() {
    state=$(osascript -e 'tell application "Spotify" to player state as string')
    # echo $state >> /tmp/.debug_sketchbar
    if [ "$state" = "paused" ]; then
    echo "Paused"
    else
        # echo "Playing"
        TRACK=$(osascript -e 'tell application "Spotify" to name of current track as string')
        ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track as string')
        sketchybar --set spotify.name label="$TRACK 􀉮 $ARTIST"
        # echo "$TRACK - $ARTIST" >> /tmp/.debug_sketchbar
    fi

}
# echo "RUNNING $SENDER $NAME $INFO" >> /tmp/.debug_sketchbar

mouse_clicked() {
  case "$NAME" in
    "spotify.name") toggle ;;
    "spotify.next") next ;;
    "spotify.back") back ;;
    "spotify.play") play ;;
    "spotify.shuffle") shuffle ;;
    "spotify.repeat") repeat ;;
    *) exit ;;
  esac
}

forced() {
    case "$NAME" in
        "spotify.name") get_info ;;
        *) exit ;;
    esac
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  "mouse.entered") popup on ;;
  "forced") forced on ;;
  "mouse.exited"|"mouse.exited.global") popup off ;;
  *) update ;;
esac