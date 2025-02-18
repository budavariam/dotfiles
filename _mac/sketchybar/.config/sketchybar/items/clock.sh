#!/usr/bin/env bash

sketchybar --add item clock right \
      --set clock update_freq=10 icon= script="$PLUGIN_DIR/clock.sh" \
      --subscribe clock system_woke