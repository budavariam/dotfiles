#!/usr/bin/env bash
# Replace the 'Z' zoom flag with a nerd font magnifier icon in window-status formats.
# Called from .tmux.conf after tpm initializes.

has_nerd_font() {
    ls ~/Library/Fonts/ /Library/Fonts/ 2>/dev/null | grep -qi "nerd"
}

if has_nerd_font; then
    ICON='󰍉'
else
    ICON='Z'
fi

patch() {
    local opt="$1"
    local current
    current=$(tmux show-options -gwv "$opt" 2>/dev/null) || return
    # Replace literal #F with tmux's s/// substitution that swaps Z at display time
    local patched="${current//#F/#{s/Z/${ICON}/:window_flags\}}"
    tmux set-option -gw "$opt" "$patched"
}

patch window-status-format
patch window-status-current-format
