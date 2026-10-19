#!/usr/bin/env sh

# Color Palette

BLACK=0xf0111111
WHITE=0xaaffffff
MAGENTA=0xffbb9af7
BLUE=0xff7aa2f7
CYAN=0xff7dcfff
GREEN=0xff9ece6a
YELLOW=0xffe0af68
PURPLE=0xff5e5ce6
ORANGE=0xffff9e64
RED=0xfff7768e

TRANSPARENT=0x00000000

# General bar colors
ICON_COLOR=$WHITE  # Color of all icons
LABEL_COLOR=$WHITE # Color of all labels

ITEM_DIR="$HOME/.config/sketchybar/items"
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# https://www.programmingfonts.org/#jetbrainsmono
FONT="JetBrainsMono Nerd Font"

INNER_PADDINGS=5
PADDINGS=3

POPUP_BORDER_WIDTH=2
POPUP_CORNER_RADIUS=5
BACKGROUND_COLOR=$BLACK
POPUP_BACKGROUND_COLOR=$BLACK
POPUP_HIGHLIGHT_COLOR=$RED
POPUP_BORDER_COLOR=$WHITE
BAR_COLOR=$BLACK

CORNER_RADIUS=15
BORDER_WIDTH=1

SHADOW=on

# AI sessions dropdown (plugins/ai_sessions.py) - row order.
# AI_SORT_BY: tool | app | session | branch | model | ctx | age | idle | pid
#   (numeric columns sort by value, text columns naturally - never plain lexicographic)
# AI_SORT_DIR: asc | desc
AI_SORT_BY="idle"
AI_SORT_DIR="asc"

# AI tools detected by process, one per line: Label=extended regex matched against
# the process's full command line (ps args). Claude Code is not listed here: it is
# read from ~/.claude/sessions (hooks give it status, needs-action, model, context).
# Use only regex syntax shared by awk and python: no \s \d, use [^ ] and " +".
# Add your own tool by appending a line. A process whose parent matches the same
# tool is ignored (node launcher -> native binary counts once).
AI_TOOLS='Gemini=^(([^ ]*/)?(node|python[0-9.]*) +)?([^ ]*/)?gemini( |$)
Codex=^(([^ ]*/)?(node|python[0-9.]*) +)?([^ ]*/)?codex( |$)
Ollama=^([^ ]*/)?ollama run( |$)
Aider=^(([^ ]*/)?(node|python[0-9.]*) +)?([^ ]*/)?aider( |$)
OpenCode=^(([^ ]*/)?(node|python[0-9.]*) +)?([^ ]*/)?opencode( |$)
Antigravity=/Antigravity\.app/Contents/MacOS/
Claude Desktop=/Claude\.app/Contents/MacOS/'
export AI_TOOLS
