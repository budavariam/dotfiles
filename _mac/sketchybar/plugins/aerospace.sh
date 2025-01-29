#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

# Update the label of the main workspace indicator
if [ -z "$FOCUSED_WORKSPACE" ]; then
    # NOTE: on first start it can be empty, get it from aerospace
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused) 
    sketchybar --set current_workspace label="$FOCUSED_WORKSPACE"
else
    sketchybar --set current_workspace label="$FOCUSED_WORKSPACE"
fi

# Reset the bgcolor for all subitems with regex, and set the color of the curent selected
sketchybar --set "/space\.s_.*/" background.color=0x55000000
sketchybar --set "space.s_$FOCUSED_WORKSPACE" background.color=0x55FF0000
