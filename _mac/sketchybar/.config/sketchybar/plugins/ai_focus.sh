#!/bin/sh
# Usage: ai_focus.sh <pid> [cwd]
# Focuses the terminal/editor hosting an AI tool session: iTerm2 (window+tab),
# tmux (pane, then the attached client's iTerm tab), VS Code (window by folder),
# or any other macOS app (the tool's own app, or the app hosting it) by process id.
# Set AI_FOCUS_DEBUG=1 to log decisions to /tmp/ai-focus.log.

PID="$1"
CWD="$2"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

log() { [ -n "$AI_FOCUS_DEBUG" ] && echo "$(date +%T) $*" >> /tmp/ai-focus.log; }

[ -n "$PID" ] || exit 1

tty_of() { ps -o tty= -p "$1" 2>/dev/null | tr -d ' '; }

focus_iterm_tty() { # $1 = tty name like ttys003
  /usr/bin/osascript - "/dev/$1" <<'OSA'
on run argv
  set target to item 1 of argv
  tell application "iTerm2"
    repeat with w in windows
      repeat with t in tabs of w
        repeat with s in sessions of t
          if tty of s is target then
            select w
            select t
            select s
            activate
            return "ok"
          end if
        end repeat
      end repeat
    end repeat
  end tell
  return "notfound"
end run
OSA
}

TTY=$(tty_of "$PID")
[ "$TTY" = "??" ] && TTY=""  # GUI apps have no tty
log "pid=$PID tty=$TTY cwd=$CWD"

# 1. tmux: the pane owning this tty -> select it, then focus the client showing it
if [ -n "$TTY" ] && command -v tmux >/dev/null && tmux list-sessions >/dev/null 2>&1; then
  pane=$(tmux list-panes -a -F '#{pane_tty} #{session_name} #{window_index} #{pane_id}' \
    | awk -v t="/dev/$TTY" '$1 == t { print $2, $3, $4 }')
  if [ -n "$pane" ]; then
    read -r sess win pane_id <<EOF
$pane
EOF
    log "tmux $sess:$win $pane_id"
    tmux select-window -t "$sess:$win"
    tmux select-pane -t "$pane_id"
    client_tty=$(tmux list-clients -t "$sess" -F '#{client_tty}' | head -1)
    log "tmux client tty=$client_tty"
    [ -n "$client_tty" ] && focus_iterm_tty "${client_tty#/dev/}" >/dev/null
    exit 0
  fi
fi

# 2. Walk ancestors to detect the host app
q="$PID"
host=""
for _ in $(seq 1 15); do
  comm=$(ps -o comm= -p "$q" 2>/dev/null)
  case "$comm" in
    *iTerm*) host=iterm; break ;;
    *"Visual Studio Code"*|*"Code Helper"*|*Electron*) host=vscode; break ;;
    *.app/Contents/MacOS/*) host=app; app_pid="$q"; break ;;
  esac
  q=$(ps -o ppid= -p "$q" 2>/dev/null | tr -d ' ')
  [ -z "$q" ] || [ "$q" = 0 ] || [ "$q" = 1 ] && break
done
log "host=$host"

case "$host" in
  iterm) focus_iterm_tty "$TTY" ;;
  vscode)
    if [ -n "$CWD" ] && [ -d "$CWD" ]; then
      code -r "$CWD"  # reuses the window that already has this folder open
    else
      open -a "Visual Studio Code"
    fi
    ;;
  app)
    /usr/bin/osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $app_pid) to true" >/dev/null
    ;;
  *) log "unknown host; nothing to focus" ;;
esac
