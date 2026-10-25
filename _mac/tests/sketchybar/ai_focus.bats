#!/usr/bin/env bats
# Tests for sketchybar/.config/sketchybar/plugins/ai_focus.sh (focus the host of an AI session)
# ps/tmux/osascript/code/open/sleep are stubs; the process table is fixture files in $PS_DIR.

load helper

setup() {
  setup_stubs
  unset AI_FOCUS_DEBUG
  export AI_FOCUS_KEEP_PATH=1
  export PS_DIR="$BATS_TEST_TMPDIR/ps"
  mkdir -p "$PS_DIR"
  # ps -o <field>= -p <pid>  ->  $PS_DIR/<field>.<pid>
  stub_script ps 'cat "$PS_DIR/${2%=}.$4" 2>/dev/null'
  stub_script tmux 'echo "$@" >> "$STUB_BIN/tmux.log"
case "$1" in
  list-sessions) exit "${TMUX_RC:-1}" ;;
  list-panes) printf "%s\n" "$TMUX_PANES" ;;
  list-clients) printf "%s\n" "$TMUX_CLIENTS" ;;
esac'
  stub_logged osascript
  stub_logged code
  stub_logged open
  stub_script sleep 'exit 0'
}

# proc <pid> <tty> <comm> <ppid>
proc() {
  printf '%s\n' "$2" > "$PS_DIR/tty.$1"
  printf '%s\n' "$3" > "$PS_DIR/comm.$1"
  printf '%s\n' "$4" > "$PS_DIR/ppid.$1"
}

# chain: 100 (node) -> 200 (zsh) -> 300 (host $1), host's parent is launchd
chain() {
  proc 100 ttys004 node 200
  proc 200 ttys004 -zsh 300
  proc 300 ttys004 "$1" 1
}

run_focus() { run sh "$PLUGINS/ai_focus.sh" "$@"; }

@test "missing pid exits 1 without touching anything" {
  run_focus
  [ "$status" -eq 1 ]
  [ -z "$(calls osascript)$(calls code)$(calls open)$(calls tmux)" ]
}

@test "tmux pane found: selects window and pane, focuses the client's iTerm tty" {
  chain /bin/zsh
  export TMUX_RC=0
  export TMUX_PANES=$'/dev/ttys001 main 0 %1\n/dev/ttys004 work 2 %7'
  export TMUX_CLIENTS='/dev/ttys009'
  run_focus 100
  [ "$status" -eq 0 ]
  calls tmux | grep -qx 'select-window -t work:2'
  calls tmux | grep -qx 'select-pane -t %7'
  calls tmux | grep -qx 'list-clients -t work -F #{client_tty}'
  [ "$(calls osascript)" = "- /dev/ttys009" ]
  [ -z "$(calls open)$(calls code)" ]
}

@test "tmux pane found but no attached client: no iTerm focus" {
  chain /bin/zsh
  export TMUX_RC=0
  export TMUX_PANES='/dev/ttys004 work 2 %7'
  export TMUX_CLIENTS=''
  run_focus 100
  [ "$status" -eq 0 ]
  calls tmux | grep -qx 'select-pane -t %7'
  [ -z "$(calls osascript)" ]
}

@test "tmux running but no pane owns the tty: falls through to host detection" {
  chain "/Applications/iTerm.app/Contents/MacOS/iTerm2"
  export TMUX_RC=0
  export TMUX_PANES='/dev/ttys777 other 0 %3'
  run_focus 100
  [ "$status" -eq 0 ]
  ! calls tmux | grep -q select-
  [ "$(calls osascript)" = "- /dev/ttys004" ]
}

@test "tmux not running: tmux is not asked for panes" {
  chain "/Applications/iTerm.app/Contents/MacOS/iTerm2"
  run_focus 100
  ! calls tmux | grep -q list-panes
}

@test "iTerm host: focuses the process's own tty" {
  chain "/Applications/iTerm.app/Contents/MacOS/iTerm2"
  run_focus 100
  [ "$status" -eq 0 ]
  [ "$(calls osascript)" = "- /dev/ttys004" ]
  [ -z "$(calls open)$(calls code)" ]
}

@test "VS Code host with an existing cwd: code -r, then URI with the ancestor chain" {
  chain "/Applications/Visual Studio Code.app/Contents/MacOS/Electron"
  mkdir -p "$BATS_TEST_TMPDIR/proj"
  run_focus 100 "$BATS_TEST_TMPDIR/proj"
  [ "$status" -eq 0 ]
  [ "$(calls code)" = "-r $BATS_TEST_TMPDIR/proj" ]
  [ "$(calls open)" = "vscode://budavariam.ai-focus/terminal?pids=100,200,300" ]
  [ -z "$(calls osascript)" ]
}

@test "VS Code host without cwd: opens the app, still sends the terminal URI" {
  chain "/Applications/Visual Studio Code.app/Contents/MacOS/Electron"
  run_focus 100
  [ "$status" -eq 0 ]
  [ -z "$(calls code)" ]
  calls open | grep -qx -- '-a Visual Studio Code'
  calls open | grep -qx 'vscode://budavariam.ai-focus/terminal?pids=100,200,300'
}

@test "VS Code host with a cwd that does not exist: treated as no cwd" {
  chain "/x/Code Helper (Renderer)"
  run_focus 100 "$BATS_TEST_TMPDIR/missing"
  [ -z "$(calls code)" ]
  calls open | grep -qx -- '-a Visual Studio Code'
}

@test "ancestor walk stops at pid 1 (launchd is not in the URI)" {
  chain "/Applications/Cursor.app/Contents/MacOS/Electron"
  echo launchd > "$PS_DIR/comm.1"; echo 0 > "$PS_DIR/ppid.1"
  run_focus 100
  calls open | grep -qx 'vscode://budavariam.ai-focus/terminal?pids=100,200,300'
}

@test "generic .app host: raises it by unix id via System Events" {
  chain "/Applications/Ghostty.app/Contents/MacOS/ghostty"
  run_focus 100
  [ "$status" -eq 0 ]
  calls osascript | grep -qF 'unix id is 300'
  [ -z "$(calls open)$(calls code)" ]
}

@test "GUI process without a tty (??) that is itself an app: raised by its own pid" {
  proc 100 '??' "/Applications/Foo.app/Contents/MacOS/Foo" 1
  run_focus 100
  calls osascript | grep -qF 'unix id is 100'
  ! calls tmux | grep -q list-panes
}

@test "unknown host: nothing is focused" {
  chain /usr/bin/login
  run_focus 100
  [ -z "$(calls osascript)$(calls code)$(calls open)" ]
}
