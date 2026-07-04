#!/usr/bin/env record-asciinema
# record-asciinema-demo — Screenplay showcasing every available function.
#
# Usage:
#   record-asciinema _record-asciinema-demo.sh [output.cast]
#
# Screenplays are plain bash scripts — variables, loops, and conditionals
# all work. The API functions (run, pause, …) are just bash functions.
#
# ── Function reference ────────────────────────────────────────────────────────
#
#  Function              What it does
#  ──────────────────    ────────────────────────────────────────────────────
#  run "cmd"             type cmd char-by-char, press Enter, wait for output
#  type_text "text"      type text char-by-char (no Enter pressed)
#  enter                 press Enter on its own
#  ctrl_c                send Ctrl-C  (interrupt current command)
#  pause [N]             wait N seconds (default: 1)
#  clear_screen          run 'clear'
#  blank_lines [N]       press Enter N times — breathing room (default: 1)
#
# ─────────────────────────────────────────────────────────────────────────────

# ── run: type a command and press Enter ──────────────────────────────────────
run "echo 'run: types a command and presses Enter'"
pause 1

# ── type_text + enter: split typing from submission ──────────────────────────
type_text "echo 'type_text wrote this..."
pause 0.8
type_text "and now enter is pressed separately'"
pause 0.4
enter
pause 1

# ── pause: hold on output so viewers can read ─────────────────────────────────
run "echo 'pause 2 gives viewers time to read this'"
pause 2

# ── blank_lines: visual breathing room ───────────────────────────────────────
run "echo 'blank_lines adds vertical space below'"
blank_lines 2

# ── clear_screen: start a new visual section ─────────────────────────────────
pause 0.5
clear_screen

run "echo 'clear_screen wiped the previous output'"
pause 1

# ── ctrl_c: interrupt a running command ──────────────────────────────────────
type_text "sleep 10"
enter
pause 1.5
ctrl_c
pause 0.5
run "echo 'ctrl_c interrupted the sleep'"
pause 1

clear_screen

# ── variables and loops: plain bash works inside screenplays ─────────────────
#
# Set up three folders in /tmp and echo the sequence number for each.
folders=(/tmp/demo-alpha /tmp/demo-beta /tmp/demo-gamma)

for dir in "${folders[@]}"; do
    mkdir -p "$dir"
done

i=0
for dir in "${folders[@]}"; do
    i=$((i + 1))
    run "echo \"folder $i of ${#folders[@]}: $dir\""
    run "ls '$dir'"
    pause 0.5
done

run "echo 'done — visited ${#folders[@]} folders'"
pause 1

clear_screen

# ── pause_recording / continue_recording / stop_recording ────────────────────
#
# pause_recording mutes all shell commands — use it for setup that should not
# appear in the recording. The viewer shows [PAUSED] in the progress bar.
# continue_recording resumes. stop_recording ends the recording early.

run "ls /tmp/demo-alpha"
pause 1

# Silently remove the demo folders — not recorded.
# The pause 3 keeps the [PAUSED] indicator visible long enough to validate.
pause_recording
rm -rf /tmp/demo-alpha /tmp/demo-beta /tmp/demo-gamma
pause 3
continue_recording

run "echo 'folders are gone'"
run "ls /tmp/demo-alpha 2>&1 || echo 'confirmed: cleaned up'"
pause 1

stop_recording
