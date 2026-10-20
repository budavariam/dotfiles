#!/bin/sh

# Polling is only on while hovered (the label is hidden otherwise), see items/cpu.sh
case "$SENDER" in
	mouse.entered)
		sketchybar --set cpu label.drawing=on update_freq=3 \
			label="$(ps -A -o %cpu | awk '{s+=$1} END {s /= 8} END {printf "%05.2f%%\n", s}')" ;;
	mouse.exited)
		sketchybar --set cpu label.drawing=off update_freq=0 ;;
	*)
		sketchybar --set "$NAME" label="$(ps -A -o %cpu | awk '{s+=$1} END {s /= 8} END {printf "%05.2f%%\n", s}')" ;;
esac
