#!/usr/bin/env bats
# Tests for the small sketchybar plugins (clock, volume, battery).
# They call bare `sketchybar`, `pmset` and `osascript`, so PATH stubs stand in for those.
# Run: bats _mac/tests/sketchybar     (brew install bats-core)

load helper

setup() {
  setup_stubs
}

# --- clock ---

@test "clock label is 'Day MM.DD. HH:MM'" {
  sh "$PLUGINS/clock.sh"
  [[ "$(cat "$SB_LOG")" =~ label=[A-Z][a-z]{2}\ [0-9]{2}\.[0-9]{2}\.\ [0-9]{2}:[0-9]{2}$ ]]
}

# --- volume ---

@test "volume_change event uses \$INFO and the matching icon" {
  SENDER=volume_change INFO=100 sh "$PLUGINS/volume.sh"
  sb_has 'icon=󰕾 label=100%'
  : > "$SB_LOG"
  SENDER=volume_change INFO=45 sh "$PLUGINS/volume.sh"
  sb_has 'icon=󰖀 label=45%'
  : > "$SB_LOG"
  SENDER=volume_change INFO=5 sh "$PLUGINS/volume.sh"
  sb_has 'icon=󰕿 label=5%'
}

@test "volume 0 shows the muted icon" {
  SENDER=volume_change INFO=0 sh "$PLUGINS/volume.sh"
  sb_has 'icon=󰖁 label=0%'
}

@test "without a volume_change event the volume is read via osascript" {
  stub osascript 70
  sh "$PLUGINS/volume.sh"
  sb_has 'icon=󰕾 label=70%'
}

# --- battery ---

battery() { # <percent> <AC|Battery>
  stub pmset "Now drawing from '$2 Power'
 -InternalBattery-0 (id=1)	$1%; discharging; 4:00 remaining present: true"
  sh "$PLUGINS/battery.sh"
}

@test "battery label is the percentage" {
  battery 85 Battery
  sb_has 'label=85%'
}

@test "battery is green at 90+ and red below 10" {
  battery 95 Battery
  sb_has 'icon.color=0xaa00FF00'
  : > "$SB_LOG"
  battery 7 Battery
  sb_has 'icon.color=0xffFF0000'
}

@test "battery is white between 10 and 89" {
  battery 50 Battery
  sb_has 'icon.color=0xaaffffff'
}

@test "charging swaps the icon" {
  battery 50 Battery
  discharging=$(cat "$SB_LOG"); : > "$SB_LOG"
  battery 50 AC
  [ "$discharging" != "$(cat "$SB_LOG")" ]
}

@test "no battery percentage does nothing" {
  stub pmset "Now drawing from 'AC Power'"
  sh "$PLUGINS/battery.sh"
  [ ! -s "$SB_LOG" ]
}
