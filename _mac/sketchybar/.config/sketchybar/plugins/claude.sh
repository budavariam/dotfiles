#!/usr/bin/env bash

ITEM="claude.status"
STATE_FILE="/tmp/claude-needs-action"
SB=/opt/homebrew/bin/sketchybar
PLUGIN_DIR="${PLUGIN_DIR:-$HOME/.config/sketchybar/plugins}"

ORANGE=0xffff9e64
RED=0xfff7768e
BLUE=0xff7aa2f7
GREEN=0xff9ece6a
WHITE=0xaaffffff

# Click clears the needs-action flag and toggles the session dropdown
if [[ "$SENDER" == "mouse.clicked" ]]; then
  echo 0 > "$STATE_FILE"
  $SB --set "$ITEM" popup.drawing=toggle
fi

# Live Claude Code sessions via ~/.claude/sessions/*.json (one file per session).
# Output: pid<TAB>status<TAB>cwd<TAB>host<TAB>name, sorted by host then name so rows
# of the same app sit together. EPERM still counts as alive.
sessions=$(/usr/bin/env python3 - <<'PY'
import glob, json, os, subprocess

# One process table snapshot to find which app hosts each session
procs = {}
try:
    out = subprocess.run(["/bin/ps", "-axo", "pid=,ppid=,comm="], capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = line.split(None, 2)
        if len(parts) == 3:
            procs[int(parts[0])] = (int(parts[1]), parts[2])
except Exception:
    pass

HOSTS = [  # (substring of executable path, display name)
    ("iTerm", "iTerm"), ("Visual Studio Code", "VS Code"), ("Code Helper", "VS Code"),
    ("Cursor", "Cursor"), ("Ghostty", "Ghostty"), ("WezTerm", "WezTerm"),
    ("Alacritty", "Alacritty"), ("kitty", "kitty"), ("Terminal.app", "Terminal"),
    ("/tmux", "tmux"),
]

def host_of(pid):
    seen = 0
    while pid in procs and seen < 20:
        ppid, comm = procs[pid]
        for needle, name in HOSTS:
            if needle in comm:
                return name
        pid, seen = ppid, seen + 1
    return "unknown"

rows = []
for f in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
    try:
        d = json.load(open(f))
        pid = int(d["pid"])
    except Exception:
        continue
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        continue
    except PermissionError:
        pass
    clean = lambda s: str(s).replace("\t", " ").replace("\n", " ")
    cwd = clean(d.get("cwd", ""))
    rows.append((host_of(pid), clean(d.get("name") or os.path.basename(cwd)),
                 pid, clean(d.get("status", "?")), cwd))
for host, name, pid, status, cwd in sorted(rows):
    print("\t".join([str(pid), status, cwd, host, name]))
PY
)

session_count=0
[ -n "$sessions" ] && session_count=$(printf '%s\n' "$sessions" | wc -l | tr -d ' ')

needs_action=0
[ "$(cat "$STATE_FILE" 2>/dev/null)" = "1" ] && needs_action=1

# Rebuild the popup rows (only when the session set/status changed, to avoid flicker)
SIG_FILE="/tmp/claude-sessions-sig"
sig=$(printf '%s' "$sessions" | cksum)
if [ "$sig" != "$(cat "$SIG_FILE" 2>/dev/null)" ]; then
  # Nerd Font glyphs (JetBrainsMono NFM) - fixed-width so the columns line up
  ICON_BUSY=$'\uf110'   # fa-spinner
  ICON_IDLE=$'\uf111'   # fa-circle
  FONT_NF="JetBrainsMono Nerd Font Mono"
  host_w=0; name_w=0
  while IFS=$'\t' read -r pid status cwd host name; do
    [ -n "$pid" ] || continue
    [ ${#host} -gt $host_w ] && host_w=${#host}
    [ ${#name} -gt $name_w ] && name_w=${#name}
  done <<< "$sessions"
  args=(--remove '/claude\.session\..*/')
  while IFS=$'\t' read -r pid status cwd host name; do
    [ -n "$pid" ] || continue
    case "$status" in
      busy) dot=$BLUE; status_icon=$ICON_BUSY ;;
      *) dot=$GREEN; status_icon=$ICON_IDLE ;;
    esac
    case "$host" in
      iTerm|Terminal|Ghostty|WezTerm|Alacritty|kitty) host_icon=$'\uf120' ;; # fa-terminal
      "VS Code"|Cursor) host_icon=$'\U000f0a1e' ;;                          # md-microsoft_visual_studio_code
      tmux) host_icon=$'\uebc8' ;;                                          # cod-terminal_tmux
      *) host_icon=$'\uf128' ;;                                             # fa-question
    esac
    label=$(printf '%s  %-*s  %-*s  %6s' "$host_icon" "$host_w" "$host" "$name_w" "$name" "$pid")
    args+=(--add item "claude.session.$pid" popup.$ITEM
      --set "claude.session.$pid"
      icon="$status_icon" icon.color="$dot" icon.font="$FONT_NF:Regular:13.0"
      icon.padding_left=8 icon.padding_right=6
      label="$label" label.color="$WHITE" label.font="$FONT_NF:Regular:13.0"
      label.padding_right=8
      background.drawing=off
      click_script="$PLUGIN_DIR/claude_focus.sh $pid $(printf '%q' "$cwd"); $SB --set $ITEM popup.drawing=off")
  done <<< "$sessions"
  $SB "${args[@]}" && echo "$sig" > "$SIG_FILE"
fi

if [ "$session_count" = "0" ]; then
  echo 0 > "$STATE_FILE"
  $SB --set "$ITEM" drawing=off popup.drawing=off
  exit 0
fi

if [ "$needs_action" = "1" ]; then
  LABEL="${session_count}!"
  ICON_COLOR=$RED
  LABEL_COLOR=$RED
else
  LABEL="$session_count"
  ICON_COLOR=$ORANGE
  LABEL_COLOR=$WHITE
fi

$SB --set "$ITEM" \
  drawing=on \
  icon.color="$ICON_COLOR" \
  label="$LABEL" \
  label.color="$LABEL_COLOR" \
  label.drawing=on
