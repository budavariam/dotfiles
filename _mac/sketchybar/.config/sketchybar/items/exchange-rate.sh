#!/usr/bin/env bash

COLOR="$WHITE"

cnf_currency_euro=(
     icon=
     icon.padding_right=2
     label.padding_left=0
)
cnf_currency_usd=(
     icon.padding_right=2
     label.padding_left=0
     label.padding_right=0
     icon=""
)
cnf_currency_item=(
     label.drawing=off
     icon.drawing=off
)
cnf_currency_bracket=(
     icon=""
     associated_display=active
     script="$PLUGIN_DIR/exchange-rate.sh"
     icon.color="$COLOR"
     update_freq=1800
     label.color="$COLOR"
     background.drawing=on
     background.corner_radius="$CORNER_RADIUS"
     background.border_color="$WHITE"
     background.color="$BAR_COLOR"
)

sketchybar \
     --add item currency_euro left \
     --add item currency_usd left \
     --add item currency_item left \
     --add bracket b_currency currency_item currency_euro currency_usd \
     --set currency_euro "${cnf_currency_euro[@]}" \
     --set currency_usd  "${cnf_currency_usd[@]}" \
     --set currency_item "${cnf_currency_item[@]}" \
     --set b_currency "${cnf_currency_bracket[@]}"