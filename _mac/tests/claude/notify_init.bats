#!/usr/bin/env bats
# Tests for claude/.claude/notify.init.sh (installs the needs-action hooks into the gitignored settings.json)
# Run: bats _mac/tests/claude     (brew install bats-core jq)

SRC="$BATS_TEST_DIRNAME/../../claude/.claude"

setup() {
  # The installer derives hook paths from its own directory, so run a copy in a temp dir
  DIR="$BATS_TEST_TMPDIR/claude"
  mkdir -p "$DIR"
  cp "$SRC/notify.init.sh" "$SRC/notify.sh" "$SRC/sketchybar-claude-update.sh" "$DIR/"
  S="$DIR/settings.json"
  UPD="$DIR/sketchybar-claude-update.sh"
}

# hooks <event>: every command registered for the event, one per line, prefixed by its matcher
hooks() { jq -r --arg e "$1" '.hooks[$e][]? | (.matcher // "-") as $m | .hooks[].command | "\($m)\t\(.)"' "$S"; }

@test "fresh install: question flags on PreToolUse, clear on PostToolUse and Stop" {
  run bash "$DIR/notify.init.sh"
  [ "$status" -eq 0 ]
  hooks PreToolUse | grep -E '^AskUserQuestion.*set-needs-action'
  hooks PostToolUse | grep -qF "$UPD clear-needs-action"
  hooks Stop | grep -qF "$UPD clear-needs-action"
  hooks Stop | grep -qF "$UPD refresh"
  hooks Notification | grep -qF "$DIR/notify.sh"
}

@test "nothing clears the flag on PreToolUse (it would wipe the question's flag)" {
  bash "$DIR/notify.init.sh"
  [ -z "$(hooks PreToolUse | grep 'clear-needs-action')" ]
}

@test "the question hook is gone from PostToolUse" {
  bash "$DIR/notify.init.sh"
  [ -z "$(hooks PostToolUse | grep '^AskUserQuestion')" ]
}

@test "idempotent: a second run changes nothing" {
  bash "$DIR/notify.init.sh"
  cp "$S" "$BATS_TEST_TMPDIR/first.json"
  bash "$DIR/notify.init.sh"
  diff "$BATS_TEST_TMPDIR/first.json" "$S"
}

@test "migrates the old layout and keeps unrelated hooks" {
  cat > "$S" <<JSON
{"hooks":{
 "PostToolUse":[
  {"matcher":"AskUserQuestion","hooks":[{"type":"command","command":"x; $UPD set-needs-action"}]},
  {"matcher":"Bash","hooks":[{"type":"command","command":"keep-post"}]}],
 "PreToolUse":[
  {"hooks":[{"type":"command","command":"$UPD clear-needs-action"}]},
  {"hooks":[{"type":"command","command":"keep-pre"}]}]}}
JSON
  bash "$DIR/notify.init.sh"
  [ -z "$(hooks PostToolUse | grep '^AskUserQuestion')" ]
  hooks PreToolUse | grep -E '^AskUserQuestion.*set-needs-action'
  [ -z "$(hooks PreToolUse | grep 'clear-needs-action')" ]
  hooks PostToolUse | grep -qF "$UPD clear-needs-action"
  hooks PreToolUse | grep -qF keep-pre
  hooks PostToolUse | grep -qF keep-post
}
