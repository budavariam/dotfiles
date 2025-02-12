#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

COLOR_GREEN="0xaa00FF00"
COLOR_DEFAULT="0xaaffffff"
COLOR_RED="0xffFF0000"
COLOR="0xaaffffff"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
  9[0-9]|100)
    ICON=""
    COLOR="$COLOR_GREEN"
  ;;
  [6-8][0-9])
    ICON=""
    COLOR="${COLOR_DEFAULT}"
  ;;
  [3-5][0-9])
    ICON=""
    COLOR="${COLOR_DEFAULT}"
  ;;
  [1-2][0-9])
    ICON=""
    COLOR="${COLOR_DEFAULT}"
  ;;
  *)
    ICON=""
    COLOR="${COLOR_RED}"
  ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON=""
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" icon.color="${COLOR}" label="${PERCENTAGE}%" # label.color="${COLOR}"
