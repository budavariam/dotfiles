# Shared helpers for the sketchybar plugin tests. Use with: load helper
#
# Plugins call bare `sketchybar`, `osascript`, `pmset`, ... so the tests put stubs first on PATH.
# Every call to the sketchybar stub is appended to $SB_LOG, one line per call.

PLUGINS="$BATS_TEST_DIRNAME/../../sketchybar/.config/sketchybar/plugins"

setup_stubs() {
  export SB_LOG="$BATS_TEST_TMPDIR/sb.log"
  export STUB_BIN="$BATS_TEST_TMPDIR/bin"
  export NAME=item
  mkdir -p "$STUB_BIN"
  : > "$SB_LOG"
  stub_script sketchybar 'echo "$@" >> "$SB_LOG"'
  export PATH="$STUB_BIN:$PATH"
}

# stub_script <name> <sh body>: a command on PATH running the given body
stub_script() {
  printf '#!/bin/sh\n%s\n' "$2" > "$STUB_BIN/$1"
  chmod +x "$STUB_BIN/$1"
}

# stub <name> <stdout>: a command on PATH that prints a fixed string
stub() {
  export "STUB_OUT_$1=$2"
  stub_script "$1" "printf '%s\\n' \"\$STUB_OUT_$1\""
}

# stub_logged <name> [stdout]: prints stdout, appends its args to $STUB_BIN/<name>.log
stub_logged() {
  export "STUB_OUT_$1=${2-}"
  stub_script "$1" "echo \"\$@\" >> \"$STUB_BIN/$1.log\"; printf '%s' \"\$STUB_OUT_$1\""
}

# calls <name>: the logged calls of a stub_logged command
calls() { cat "$STUB_BIN/$1.log" 2>/dev/null; }

# sb_has <substring>: true if any sketchybar call contained the substring
sb_has() { grep -qF -- "$1" "$SB_LOG"; }
