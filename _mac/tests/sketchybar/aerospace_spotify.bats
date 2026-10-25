#!/usr/bin/env bats
# Tests for plugins/aerospace.sh (workspace labels + window popup) and plugins/spotify.sh (player controls).
# Run: bats _mac/tests/sketchybar     (brew install bats-core)

load helper

setup() {
  setup_stubs
  command -v jq >/dev/null || skip "jq not installed"
  export AEROSPACE_CACHE="$BATS_TEST_TMPDIR/cache"
  export OSA_LOG="$BATS_TEST_TMPDIR/osa.log"
  : > "$OSA_LOG"
  # sketchybar stub: log every call, answer --query with $SB_QUERY
  stub_script sketchybar 'echo "$@" >> "$SB_LOG"; [ "$1" = "--query" ] && printf "%s\n" "$SB_QUERY"; exit 0'
  export SB_QUERY='{}'
  # osascript stub: log the script, answer by subcommand
  stub_script osascript 'echo "$*" >> "$OSA_LOG"
case "$*" in
  *"is running"*) echo "${OSA_RUNNING-true}" ;;
  *"get shuffling"*) echo "$OSA_SHUFFLE" ;;
  *"get repeating"*) echo "$OSA_REPEAT" ;;
  *"player state"*) echo "$OSA_STATE" ;;
  *"name of current track"*) echo "$OSA_TRACK" ;;
  *"artist of current track"*) echo "$OSA_ARTIST" ;;
esac'
  # aerospace stub: logs calls, answers from AS_* variables
  export AS_LOG="$BATS_TEST_TMPDIR/as.log"
  : > "$AS_LOG"
  stub_script aerospace 'echo "$*" >> "$AS_LOG"
case "$*" in
  "list-workspaces --focused") printf "%s\n" "$AS_FOCUSED" ;;
  "list-monitors") printf "%s\n" "$AS_MONITORS" ;;
  "list-workspaces --monitor "*) eval "printf \"%s\n\" \"\$AS_MON_$3\"" ;;
  "list-windows --all"*) [ -z "$AS_WINDOWS" ] || printf "%s\n" "$AS_WINDOWS" ;;
esac'
  export AS_MONITORS=$'1 | Built-in Retina Display\n2 | Sidecar Display'
  export AS_MON_1=$'1\n2' AS_MON_2=$'7\n8'
  export AS_FOCUSED=1
}

aero() { bash "$PLUGINS/aerospace.sh"; }
spot() { bash "$PLUGINS/spotify.sh"; }
osa_has() { grep -qF -- "$1" "$OSA_LOG"; }
# `! cmd` never fails a bats test, so negations are explicit
not_sb() { ! sb_has "$1" || { echo "unexpected sketchybar call: $1"; return 1; }; }
not_osa() { ! osa_has "$1" || { echo "unexpected osascript call: $1"; return 1; }; }

# ---------- aerospace.sh ----------

@test "aerospace: app not running hides label and popup, touches nothing else" {
  export OSA_RUNNING=false SENDER=forced
  run aero
  [ "$status" -eq 0 ]
  [[ "$output" == *"Aerospace is not running"* ]]
  sb_has "--set item label= label.drawing=off popup.drawing=off"
  [ ! -s "$AS_LOG" ]
  [ ! -e "$AEROSPACE_CACHE" ]
}

@test "aerospace: focused workspace on main monitor is cached in disp1" {
  export SENDER=forced AS_FOCUSED=2
  run aero
  [ "$status" -eq 0 ]
  [ "$(cat "$AEROSPACE_CACHE/disp1")" = "2" ]
  sb_has "--set current_workspace_1 label.drawing=on label=2"
}

@test "aerospace: focused workspace on secondary monitor is cached in disp2 only" {
  export SENDER=forced AS_FOCUSED=8
  mkdir -p "$AEROSPACE_CACHE"; echo 1 > "$AEROSPACE_CACHE/disp1"
  run aero
  [ "$(cat "$AEROSPACE_CACHE/disp2")" = "8" ]
  [ "$(cat "$AEROSPACE_CACHE/disp1")" = "1" ]
  sb_has "--set current_workspace_2 label.drawing=on label=8"
  sb_has "--set current_workspace_1 label.drawing=on label=1"
}

@test "aerospace: first run seeds both caches from each monitor's first workspace" {
  export SENDER=forced AS_FOCUSED=1
  run aero
  [ "$(cat "$AEROSPACE_CACHE/disp1")" = "1" ]
  [ "$(cat "$AEROSPACE_CACHE/disp2")" = "7" ]
  sb_has "--set current_workspace_2 label.drawing=on label=7"
}

@test "aerospace: existing disp2 cache is kept when focus is on main" {
  export SENDER=forced AS_FOCUSED=2
  mkdir -p "$AEROSPACE_CACHE"; echo 9 > "$AEROSPACE_CACHE/disp2"
  run aero
  [ "$(cat "$AEROSPACE_CACHE/disp2")" = "9" ]
  sb_has "--set current_workspace_2 label.drawing=on label=9"
}

@test "aerospace: without a Built-in monitor, main is the first non-Sidecar/AirPlay one" {
  export SENDER=forced AS_FOCUSED=7
  export AS_MONITORS=$'1 | AirPlay Display\n2 | Studio Display'
  export AS_MON_1=$'1' AS_MON_2=$'7'
  run aero
  [ "$(cat "$AEROSPACE_CACHE/disp1")" = "7" ]
  [ "$(cat "$AEROSPACE_CACHE/disp2")" = "1" ]
}

@test "aerospace: FOCUSED_WORKSPACE overrides the focused query" {
  export SENDER=forced AS_FOCUSED=1 FOCUSED_WORKSPACE=2
  run aero
  [ "$(cat "$AEROSPACE_CACHE/disp1")" = "2" ]
}

@test "aerospace: no monitors means no labels set" {
  export SENDER=forced AS_MONITORS=""
  run aero
  [ "$status" -eq 0 ]
  [ ! -s "$SB_LOG" ]
}

@test "aerospace: no focused workspace means no labels set" {
  export SENDER=forced AS_FOCUSED=""
  run aero
  [ ! -s "$SB_LOG" ]
  [ ! -e "$AEROSPACE_CACHE/disp1" ]
}

@test "aerospace: popup items get per-workspace colours, click script and shared width" {
  export SENDER=mouse.clicked NAME=current_workspace_1 AS_FOCUSED=1 SB_QUERY='{"popup":{"drawing":"off"}}'
  export AS_WINDOWS=$'1 | Safari (Home)                              |42\nB | Mail (Inbox)                              |43\n2 | Terminal (zsh)                              |44'
  run aero
  [ "$status" -eq 0 ]
  sb_has '--remove /space\.s_.*/'
  # focused single-digit workspace
  sb_has '--add item space.s_1_0 popup.current_workspace_1'
  sb_has 'label=1 | Safari (Home) background.color=0x99FF4444'
  # non-focused single-digit workspace
  sb_has 'label=2 | Terminal (zsh) background.color=0x55444444'
  # non-focused named workspace
  sb_has 'label=B | Mail (Inbox) background.color=0x55000000'
  sb_has 'aerospace workspace "1";'
  sb_has 'aerospace focus --window-id "42";'
  sb_has 'sketchybar --set current_workspace_1 label="1" popup.drawing=off'
  # widest label: "2 | Terminal (zsh)" = 18 chars -> 18*8+16
  sb_has '--set /space\.s_.*/ width=160'
}

@test "aerospace: focused named workspace uses the named-focused colour" {
  export SENDER=mouse.clicked NAME=current_workspace_1 AS_FOCUSED=B SB_QUERY='{"popup":{"drawing":"off"}}'
  export AS_WINDOWS=$'B | Mail (Inbox)                              |43'
  run aero
  sb_has 'label=B | Mail (Inbox) background.color=0x55FF0000'
}

@test "aerospace: click on workspace item 1 with popup closed rebuilds items then toggles" {
  export SENDER=mouse.clicked NAME=current_workspace_1 SB_QUERY='{"popup":{"drawing":"off"}}'
  export AS_WINDOWS=$'1 | Safari (Home)                              |42'
  run aero
  sb_has '--add item space.s_1_0'
  [ "$(tail -1 "$SB_LOG")" = "--set current_workspace_1 popup.drawing=toggle" ]
}

@test "aerospace: click with no popup state in query also rebuilds" {
  export SENDER=mouse.clicked NAME=current_workspace_2 SB_QUERY='{}'
  export AS_WINDOWS=$'1 | Safari (Home)                              |42'
  run aero
  sb_has '--add item space.s_1_0 popup.current_workspace_2'
  sb_has '--set current_workspace_2 popup.drawing=toggle'
}

@test "aerospace: click with popup already open only toggles" {
  export SENDER=mouse.clicked NAME=current_workspace_1 SB_QUERY='{"popup":{"drawing":"on"}}'
  run aero
  not_sb '--add item'
  not_sb '--remove'
  [ "$(tail -1 "$SB_LOG")" = "--set current_workspace_1 popup.drawing=toggle" ]
}

@test "aerospace: click on a non-workspace item only toggles" {
  export SENDER=mouse.clicked NAME=space.s_1_0 SB_QUERY='{"popup":{"drawing":"off"}}'
  run aero
  not_sb '--add item'
  sb_has '--set space.s_1_0 popup.drawing=toggle'
}

@test "aerospace: toggle event on item 2 only closes its own popup" {
  export SENDER=toggle_aerospace_popup NAME=current_workspace_2 SB_QUERY='{"popup":{"drawing":"off"}}'
  run aero
  sb_has '--set current_workspace_2 popup.drawing=off'
  not_sb 'toggle'
  not_sb '--add item'
}

@test "aerospace: toggle event on item 1 rebuilds and toggles" {
  export SENDER=toggle_aerospace_popup NAME=current_workspace_1 SB_QUERY='{"popup":{"drawing":"off"}}'
  export AS_WINDOWS=$'1 | Safari (Home)                              |42'
  run aero
  sb_has '--add item space.s_1_0'
  sb_has '--set current_workspace_1 popup.drawing=toggle'
}

@test "aerospace: no windows means no width is set" {
  export SENDER=mouse.clicked NAME=current_workspace_1 SB_QUERY='{"popup":{"drawing":"off"}}' AS_WINDOWS=""
  run aero
  not_sb '--add item'
  not_sb 'width='
  sb_has '--set current_workspace_1 popup.drawing=toggle'
}

# ---------- spotify.sh ----------

@test "spotify: app not running hides label and popup, does nothing else" {
  export OSA_RUNNING=false SENDER=mouse.clicked NAME=spotify.next
  run spot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Spotify is not running"* ]]
  sb_has '--set spotify.name label= label.drawing=off popup.drawing=off'
  not_osa 'next track'
}

@test "spotify: click maps next/back/play to the right Spotify command" {
  export SENDER=mouse.clicked
  NAME=spotify.next run spot; osa_has 'play next track'
  NAME=spotify.back run spot; osa_has 'play previous track'
  NAME=spotify.play run spot; osa_has 'to playpause'
}

@test "spotify: next does not trigger back or playpause" {
  export SENDER=mouse.clicked NAME=spotify.next
  run spot
  not_osa 'previous track'
  not_osa 'playpause'
}

@test "spotify: click on name toggles the popup" {
  export SENDER=mouse.clicked NAME=spotify.name
  run spot
  sb_has '-m --set spotify.name popup.drawing=toggle'
}

@test "spotify: click on unknown item does nothing" {
  export SENDER=mouse.clicked NAME=spotify.other
  run spot
  [ "$status" -eq 0 ]
  [ ! -s "$SB_LOG" ]
  not_osa 'tell application "Spotify"'
}

@test "spotify: shuffle off turns highlight and shuffling on" {
  export SENDER=mouse.clicked NAME=spotify.shuffle OSA_SHUFFLE=false
  run spot
  sb_has '-m --set spotify.shuffle icon.highlight=on'
  osa_has 'set shuffling to true'
}

@test "spotify: shuffle on turns highlight and shuffling off" {
  export SENDER=mouse.clicked NAME=spotify.shuffle OSA_SHUFFLE=true
  run spot
  sb_has '-m --set spotify.shuffle icon.highlight=off'
  osa_has 'set shuffling to false'
}

@test "spotify: repeat off turns highlight and repeating on" {
  export SENDER=mouse.clicked NAME=spotify.repeat OSA_REPEAT=false
  run spot
  sb_has '-m --set spotify.repeat icon.highlight=on'
  osa_has 'set repeating to true'
}

@test "spotify: repeat on turns highlight and repeating off" {
  export SENDER=mouse.clicked NAME=spotify.repeat OSA_REPEAT=true
  run spot
  sb_has '-m --set spotify.repeat icon.highlight=off'
  osa_has 'set repeating to false'
}

@test "spotify: update while Playing shows track and artist, pause icon, shuffle/repeat state" {
  export SENDER=spotify_change OSA_SHUFFLE=true OSA_REPEAT=false
  export INFO='{"Player State":"Playing","Name":"Song","Artist":"Band","Album":"Record"}'
  run spot
  sb_has '-m --set spotify.name label=Song 􀉮 Band label.drawing=on --set spotify.play icon=􀊆 --set spotify.shuffle icon.highlight=true --set spotify.repeat icon.highlight=false'
}

@test "spotify: update truncates track, artist to 20 characters" {
  export SENDER=spotify_change OSA_SHUFFLE=false OSA_REPEAT=false
  export INFO='{"Player State":"Playing","Name":"ABCDEFGHIJKLMNOPQRSTUVWXYZ","Artist":"0123456789012345678901234","Album":"x"}'
  run spot
  sb_has 'label=ABCDEFGHIJKLMNOPQRST 􀉮 01234567890123456789 label.drawing=on'
}

@test "spotify: update falls back to album when artist is empty, truncated to 20" {
  export SENDER=spotify_change OSA_SHUFFLE=false OSA_REPEAT=false
  export INFO='{"Player State":"Playing","Name":"Song","Artist":"","Album":"ALBUMALBUMALBUMALBUMALBUM"}'
  run spot
  sb_has 'label=Song 􀉮 ALBUMALBUMALBUMALBUM label.drawing=on'
  not_sb 'ALBUMALBUMALBUMALBUMA'
}

@test "spotify: update while Paused closes popup, shows play icon, skips shuffle/repeat queries" {
  export SENDER=spotify_change
  export INFO='{"Player State":"Paused","Name":"Song","Artist":"Band","Album":"Record"}'
  run spot
  sb_has '-m --set spotify.name popup.drawing=off --set spotify.play icon=􀊄'
  not_sb 'Song'
  not_osa 'get shuffling'
  not_osa 'get repeating'
}

@test "spotify: mouse.entered opens and mouse.exited(.global) closes the popup" {
  NAME=spotify.name SENDER=mouse.entered run spot
  sb_has '--set spotify.name popup.drawing=on'
  : > "$SB_LOG"
  NAME=spotify.name SENDER=mouse.exited run spot
  sb_has '--set spotify.name popup.drawing=off'
  : > "$SB_LOG"
  NAME=spotify.name SENDER=mouse.exited.global run spot
  sb_has '--set spotify.name popup.drawing=off'
}

@test "spotify: forced on name while playing sets full label from current track" {
  export SENDER=forced NAME=spotify.name OSA_STATE=playing
  export OSA_TRACK="A Really Long Track Name Over Twenty" OSA_ARTIST="Some Artist"
  run spot
  sb_has '--set spotify.name label=A Really Long Track Name Over Twenty 􀉮 Some Artist'
}

@test "spotify: forced on name while paused prints Paused and sets no label" {
  export SENDER=forced NAME=spotify.name OSA_STATE=paused
  run spot
  [ "$output" = "Paused" ]
  [ ! -s "$SB_LOG" ]
}

@test "spotify: forced on another item does nothing" {
  export SENDER=forced NAME=spotify.play OSA_STATE=playing
  run spot
  [ ! -s "$SB_LOG" ]
  not_osa 'player state'
}
