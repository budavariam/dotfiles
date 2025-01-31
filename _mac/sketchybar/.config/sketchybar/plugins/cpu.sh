#!/usr/bin/env bash

# echo "$SENDER" >> /tmp/.debug_sketchbar
if [[ "$SENDER" == "mouse.entered" ]]; then
	sketchybar --set cpu label.drawing=on
elif [[ "$SENDER" == "mouse.exited" ]]; then
	sketchybar --set cpu label.drawing=off
else
    sketchybar --set "$NAME" label="$(ps -A -o %cpu | awk '{s+=$1} END {s /= 8} END {printf "%05.2f%%\n", s}')"
fi