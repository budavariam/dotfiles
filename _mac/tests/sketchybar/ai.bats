#!/usr/bin/env bats
# Tests for sketchybar/.config/sketchybar/plugins/ai.sh (bar label: busy/total)
# Run: bats _mac/tests/sketchybar     (brew install bats-core)
# Lives outside the stow package so `stow sketchybar` does not link it into ~.

PLUGIN="$BATS_TEST_DIRNAME/../../sketchybar/.config/sketchybar/plugins/ai.sh"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export FLAG_DIR="$BATS_TEST_TMPDIR/flags"
  export POPUP_FLAG="$BATS_TEST_TMPDIR/popup-open"
  export SB_LOG="$BATS_TEST_TMPDIR/sb.log"
  export SB="$BATS_TEST_TMPDIR/sketchybar-stub"
  mkdir -p "$HOME/.config/sketchybar" "$HOME/.claude/sessions" "$FLAG_DIR"
  # No other-tool patterns, so the real process list never affects the count
  printf 'AI_SORT_BY=idle\nAI_SORT_DIR=asc\nAI_TOOLS=""\n' > "$HOME/.config/sketchybar/variables.sh"
  printf '#!/bin/sh\necho "$@" >> "$SB_LOG"\n' > "$SB"
  chmod +x "$SB"
  PIDS=()
}

teardown() {
  [ "${#PIDS[@]}" -gt 0 ] && kill "${PIDS[@]}" 2>/dev/null
  return 0
}

# add_session <status> [sessionId]: a session file backed by a live process
add_session() {
  sleep 60 &
  local pid=$!
  PIDS+=("$pid")
  printf '{"pid":%s,"sessionId":"%s","status":"%s"}' "$pid" "${2:-sid-$pid}" "$1" \
    > "$HOME/.claude/sessions/$pid.json"
}

run_plugin() { sh "$PLUGIN"; }

@test "no sessions hides the item" {
  run run_plugin
  [ "$status" -eq 0 ]
  grep -q 'drawing=off' "$SB_LOG"
}

@test "label is busy/total" {
  add_session busy
  add_session idle
  add_session idle
  run_plugin
  grep -q 'label=1/3' "$SB_LOG"
}

@test "busy is zero-padded to the width of a two-digit total" {
  add_session busy
  add_session busy
  for _ in 1 2 3 4 5 6 7 8 9 10; do add_session idle; done
  run_plugin
  grep -q 'label=02/12' "$SB_LOG"
}

@test "single-digit total is not padded" {
  add_session idle
  run_plugin
  grep -q 'label=0/1' "$SB_LOG"
}

@test "width grows only when the total gains a digit" {
  for _ in 1 2 3 4 5 6 7 8 9; do add_session idle; done
  run_plugin
  grep -q 'label=0/9' "$SB_LOG"
  add_session idle
  run_plugin
  grep -q 'label=00/10' "$SB_LOG"
}

@test "session files of dead processes are ignored" {
  add_session busy
  sleep 0.1 & local dead=$!
  kill "$dead"; wait "$dead" || true
  printf '{"pid":%s,"sessionId":"dead","status":"busy"}' "$dead" > "$HOME/.claude/sessions/$dead.json"
  run_plugin
  grep -q 'label=1/1' "$SB_LOG"
}

@test "a session needing action appends ! to the label" {
  add_session busy sid-a
  add_session idle sid-b
  touch "$FLAG_DIR/sid-b"
  run_plugin
  grep -q 'label=1/2!' "$SB_LOG"
}
