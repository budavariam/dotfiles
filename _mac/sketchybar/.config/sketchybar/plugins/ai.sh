#!/usr/bin/env bash

ITEM="ai.status"
SB=/opt/homebrew/bin/sketchybar
PLUGIN_DIR="${PLUGIN_DIR:-$HOME/.config/sketchybar/plugins}"
source "$HOME/.config/sketchybar/variables.sh"  # AI_SORT_BY / AI_SORT_DIR / AI_TOOLS
export AI_SORT_BY AI_SORT_DIR
FLAG_DIR="/tmp/claude-needs-action.d"  # Claude Code per-session flags, see ~/.claude/sketchybar-claude-update.sh
POPUP_FLAG="/tmp/ai-popup-open"    # exists while the dropdown is open
SIG_FILE="/tmp/ai-sessions-sig"

ORANGE=0xffff9e64
RED=0xfff7768e
BLUE=0xff7aa2f7
GREEN=0xff9ece6a
DIM=0xff7f849c
HIDDEN=0x00000000  # transparent: keeps the icon column the same width as the rows
WHITE=0xaaffffff

# Nerd Font glyphs (JetBrainsMono NFM) - fixed width so the popup columns line up
ICON_BUSY=$'\xef\x84\x90'  # fa-spinner
ICON_IDLE=$'\xef\x84\x91'  # fa-circle
ICON_WAIT=$'\xef\x81\xb1'  # fa-warning
FONT_NF="JetBrainsMono Nerd Font Mono"
FONT_SIZE=11.0

# Rebuild the dropdown rows. Only called while the popup is open (or opening).
build_popup() {
  local out
  out=$(/usr/bin/env python3 -I "$PLUGIN_DIR/ai_sessions.py") || return
  # Skip the rebuild when nothing changed, to avoid flicker
  local sig
  sig=$(printf '%s' "$out" | cksum)
  [ "$1" != "force" ] && [ "$sig" = "$(cat "$SIG_FILE" 2>/dev/null)" ] && return

  local args=(--remove '/ai\.session\..*/')
  local kind pid sid status needs cwd label icon icon_color label_color sep
  while IFS=$'\t' read -r kind pid sid status needs cwd label; do
    case "$kind" in
      H)
        # H/F lines carry a single label field, which read puts in $pid
        sep=$(printf '─%.0s' $(seq 1 ${#pid}))
        args+=(--add item ai.session.header popup.$ITEM
          --set ai.session.header
          icon="$ICON_IDLE" icon.color=$HIDDEN icon.font="$FONT_NF:Regular:$FONT_SIZE"
          icon.padding_left=8 icon.padding_right=6
          label="$pid" label.color=$DIM label.font="$FONT_NF:Regular:$FONT_SIZE"
          label.padding_right=8 background.drawing=off
          --add item ai.session.sep1 popup.$ITEM
          --set ai.session.sep1
          icon="$ICON_IDLE" icon.color=$HIDDEN icon.font="$FONT_NF:Regular:$FONT_SIZE"
          icon.padding_left=8 icon.padding_right=6
          label="$sep" label.color=$DIM label.font="$FONT_NF:Regular:$FONT_SIZE"
          label.padding_right=8 background.drawing=off) ;;
      F)
        args+=(--add item ai.session.sep2 popup.$ITEM
          --set ai.session.sep2
          icon="$ICON_IDLE" icon.color=$HIDDEN icon.font="$FONT_NF:Regular:$FONT_SIZE"
          icon.padding_left=8 icon.padding_right=6
          label="$sep" label.color=$DIM label.font="$FONT_NF:Regular:$FONT_SIZE"
          label.padding_right=8 background.drawing=off
          --add item ai.session.footer popup.$ITEM
          --set ai.session.footer
          icon="$ICON_IDLE" icon.color=$HIDDEN icon.font="$FONT_NF:Regular:$FONT_SIZE"
          icon.padding_left=8 icon.padding_right=6
          label="$pid" label.color=$DIM label.font="$FONT_NF:Regular:$FONT_SIZE"
          label.padding_right=8 background.drawing=off) ;;
      R)
        if [ "$needs" = "1" ]; then
          icon=$ICON_WAIT; icon_color=$RED; label_color=$RED
        elif [ "$status" = "busy" ]; then
          icon=$ICON_BUSY; icon_color=$BLUE; label_color=$WHITE
        else
          icon=$ICON_IDLE; icon_color=$GREEN; label_color=$WHITE
        fi
        args+=(--add item "ai.session.$pid" popup.$ITEM
          --set "ai.session.$pid"
          icon="$icon" icon.color=$icon_color icon.font="$FONT_NF:Regular:$FONT_SIZE"
          icon.padding_left=8 icon.padding_right=6
          label="$label" label.color=$label_color label.font="$FONT_NF:Regular:$FONT_SIZE"
          label.padding_right=8 background.drawing=off
          click_script="$PLUGIN_DIR/ai_focus.sh $pid $(printf '%q' "$cwd"); rm -f '$FLAG_DIR/$sid' $POPUP_FLAG; $SB --set $ITEM popup.drawing=off --trigger ai_update") ;;
    esac
  done <<< "$out"
  $SB "${args[@]}" && echo "$sig" > "$SIG_FILE"
}

# Click toggles the dropdown; rows are built only when it opens
if [[ "$SENDER" == "mouse.clicked" ]]; then
  if [ -e "$POPUP_FLAG" ]; then
    rm -f "$POPUP_FLAG"
    $SB --set "$ITEM" popup.drawing=off
  else
    build_popup force
    touch "$POPUP_FLAG"
    $SB --set "$ITEM" popup.drawing=on
  fi
fi

# Cheap count + waiting check: no python (runs on every poll/hook event)
session_count=0
needs_action=0
for f in ~/.claude/sessions/*.json; do
  [ -f "$f" ] || continue
  pid=${f##*/}; pid=${pid%.json}
  kill -0 "$pid" 2>/dev/null || continue
  session_count=$((session_count + 1))
  sid=$(grep -o '"sessionId":"[^"]*"' "$f" | cut -d'"' -f4)
  [ -n "$sid" ] && [ -e "$FLAG_DIR/$sid" ] && needs_action=1
done

# Other AI tools: one ps+awk pass over the AI_TOOLS patterns, ignoring a process whose parent matches the same tool
other_count=$(/bin/ps -axo pid=,ppid=,args= | /usr/bin/awk '
  BEGIN { n = split(ENVIRON["AI_TOOLS"], lines, "\n")
          for (i = 1; i <= n; i++) { k = index(lines[i], "="); if (k) re[i] = substr(lines[i], k + 1) } }
  { pid = $1; ppid = $2; args = $0; sub(/^ *[0-9]+ +[0-9]+ +/, "", args)
    for (i in re) if (args ~ re[i]) { tool[pid] = i; par[pid] = ppid; break } }
  END { for (p in tool) if (tool[par[p]] != tool[p]) c++; print c + 0 }')
session_count=$((session_count + other_count))

if [ "$session_count" = "0" ]; then
  rm -rf "$FLAG_DIR" "$POPUP_FLAG"
  $SB --set "$ITEM" drawing=off popup.drawing=off
  exit 0
fi

# Keep an open dropdown fresh (hook events, polling)
[ -e "$POPUP_FLAG" ] && [[ "$SENDER" != "mouse.clicked" ]] && build_popup

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
