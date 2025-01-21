# Oxide theme for Zsh
#
# Author: Diki Ananta <diki1aap@gmail.com>
#   customized by: Mátyás Budavári <budavariam@gmail.com>
# Repository: https://github.com/dikiaap/dotfiles
# License: MIT

# Prompt:
# %F => Color codes
# %f => Reset color
# %~ => Current path
# %(x.true.false) => Specifies a ternary expression
#   ! => True if the shell is running with root privileges
#   ? => True if the exit status of the last command was success
#
# Git:
# %a => Current action (rebase/merge)
# %b => Current branch
# %c => Staged changes
# %u => Unstaged changes
#
# Terminal:
# \n => Newline/Line Feed (LF)

setopt PROMPT_SUBST

autoload -U add-zsh-hook
autoload -Uz vcs_info

# Use True color (24-bit) if available.
if [[ "${terminfo[colors]}" -ge 256 ]]; then
    oxide_turquoise="%F{73}"
    oxide_orange="%F{179}"
    oxide_red="%F{167}"
    oxide_limegreen="%F{107}"
    oxide_lime="%F{150}"
else
    oxide_turquoise="%F{cyan}"
    oxide_orange="%F{yellow}"
    oxide_red="%F{red}"
    oxide_limegreen="%F{green}"
    oxide_lime="%F{green}"
fi

# Reset color.
oxide_reset_color="%f"

# VCS style formats.
FMT_UNSTAGED="%{$oxide_reset_color%} %{$oxide_orange%}●"
FMT_STAGED="%{$oxide_reset_color%} %{$oxide_limegreen%}✚"
FMT_ACTION="(%{$oxide_limegreen%}%a%{$oxide_reset_color%})"
FMT_VCS_STATUS="on %{$oxide_turquoise%}%b%u%c%{$oxide_reset_color%}"

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr    "${FMT_UNSTAGED}"
zstyle ':vcs_info:*' stagedstr      "${FMT_STAGED}"
zstyle ':vcs_info:*' actionformats  "${FMT_VCS_STATUS} ${FMT_ACTION}"
zstyle ':vcs_info:*' formats        "${FMT_VCS_STATUS}"
zstyle ':vcs_info:*' nvcsformats    ""
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

# Check for untracked files.
+vi-git-untracked() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
            git status --porcelain | grep --max-count=1 '^??' &> /dev/null; then
        hook_com[staged]+="%{$oxide_reset_color%} %{$oxide_red%}●"
    fi
}

# Executed before each prompt.
add-zsh-hook precmd vcs_info

# P_TIME shows the time when the previous script finished running. It refreshes on search etc.
P_TIME='%{$oxide_lime%}[%D{%T}]%{$oxide_reset_color%}'
# P_JOBS shows the number of jobs running in the background that is handled by this shell. Query them with `jobs`. Run nth with `fg %n`
P_JOBS='%{$oxide_lime%}%j%{$oxide_reset_color%}'
# P_FOLDER shows the full path of the current folder (pwd)
P_FOLDER='%{$oxide_limegreen%}%~%{$oxide_reset_color%}'
# P_GIT shows git info of the current folder
P_GIT='${vcs_info_msg_0_}'
# P_SYMBOL prints an arrow colored red if the prev command failed, white if it ran ok
P_SYMBOL='%(?.%{%F{white}%}.%{$oxide_red%})%(!.#.❯)%{$oxide_reset_color%}'

# Oxide prompt style.
PROMPT=$''$P_FOLDER' '$P_GIT$'\n'$P_SYMBOL' '