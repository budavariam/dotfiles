#!/usr/bin/env bats
# Tests for claude/.claude/sketchybar-claude-update.sh (per-session needs-action flag + sketchybar trigger)
# Run: bats _mac/tests/claude     (brew install bats-core jq)

SCRIPT="$BATS_TEST_DIRNAME/../../claude/.claude/sketchybar-claude-update.sh"

setup() {
  export FLAG_DIR="$BATS_TEST_TMPDIR/flags"
  export SB_LOG="$BATS_TEST_TMPDIR/sb.log"
  export SKETCHYBAR="$BATS_TEST_TMPDIR/sketchybar-stub"
  export JQ="$(command -v jq)"
  printf '#!/bin/sh\necho "$@" >> "$SB_LOG"\n' > "$SKETCHYBAR"
  chmod +x "$SKETCHYBAR"
}

# hook <action> [json]: run the script the way a hook does, JSON on stdin
hook() { printf '%s' "${2-{\"session_id\":\"abc\"\}}" | "$SCRIPT" "$1"; }

@test "set-needs-action creates the flag for that session" {
  hook set-needs-action
  [ -e "$FLAG_DIR/abc" ]
}

@test "set-needs-action only flags the given session" {
  hook set-needs-action '{"session_id":"one"}'
  [ -e "$FLAG_DIR/one" ]
  [ ! -e "$FLAG_DIR/two" ]
}

@test "clear-needs-action removes only that session's flag" {
  hook set-needs-action '{"session_id":"one"}'
  hook set-needs-action '{"session_id":"two"}'
  hook clear-needs-action '{"session_id":"one"}'
  [ ! -e "$FLAG_DIR/one" ]
  [ -e "$FLAG_DIR/two" ]
}

@test "clear-needs-action without a flag succeeds and creates nothing" {
  run hook clear-needs-action
  [ "$status" -eq 0 ]
  [ ! -e "$FLAG_DIR" ]
}

@test "refresh leaves flags untouched" {
  hook set-needs-action
  hook refresh
  [ -e "$FLAG_DIR/abc" ]
}

@test "no argument behaves like refresh" {
  hook set-needs-action
  printf '{"session_id":"abc"}' | "$SCRIPT"
  [ -e "$FLAG_DIR/abc" ]
  grep -qF 'trigger claude_update' "$SB_LOG"
}

@test "every action triggers claude_update" {
  hook set-needs-action
  hook clear-needs-action
  hook refresh
  [ "$(grep -cF -- '--trigger claude_update' "$SB_LOG")" -eq 3 ]
}

@test "missing session_id falls back to the 'unknown' flag" {
  hook set-needs-action '{}'
  [ -e "$FLAG_DIR/unknown" ]
}

@test "invalid JSON on stdin falls back to 'unknown' and still triggers" {
  hook set-needs-action 'not json'
  [ -e "$FLAG_DIR/unknown" ]
  grep -qF 'claude_update' "$SB_LOG"
}

@test "a failing sketchybar does not fail the hook" {
  printf '#!/bin/sh\nexit 1\n' > "$SKETCHYBAR"
  run hook set-needs-action
  [ "$status" -eq 0 ]
  [ -e "$FLAG_DIR/abc" ]
}
