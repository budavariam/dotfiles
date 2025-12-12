# zmodload zsh/zprof # for profiling run: time  zsh -i -c exit and add 'zprof' at the end of this file
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:/opt/homebrew/bin

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="oxide"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# fzf configurations
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --scrollbar --color scrollbar:red'
# Uncomment the following line to disable fuzzy completion
# export DISABLE_FZF_AUTO_COMPLETION="true"
# Uncomment the following line to disable key bindings (CTRL-T, CTRL-R, ALT-C)
# export DISABLE_FZF_KEY_BINDINGS="true"

# docker autocompletion debug
#fpath+=($ZSH/plugins/docker)
# autoload -U compinit && compinit
# in case it doesn't work try to `rm ~/.zcompdump*`.

# # zsh-syntax-highlighting
# ## more info: https://github.com/zsh-users/zsh-syntax-highlighting/tree/master/docs/highlighters
# ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
# typeset -gA ZSH_HIGHLIGHT_STYLES
# ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold' # To differentiate aliases from other command types
# ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan' # To make globbing characters visible on black bg as well

plugins=(
  fzf-tab # to turn it on and off: toggle-fzf-tab 
  git
  zsh-autosuggestions
#  zsh-syntax-highlighting
  fzf
  docker
  kubectl
  npm
  kube-ps1 # to turn it on and off: kubeon/kubeoff
  ohmyzsh-full-autoupdate
  bam-vi-mode
)

source $ZSH/oh-my-zsh.sh

# User configuration
source $ZSH/custom/plugins/timer.zsh
source $ZSH/custom/plugins/sensitive-zshrc

bindkey -r '^K' # iterm2 AI features add an extra ctrl+K

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# kgpid usage: add an expression to grep to as the first parameter, can return more than one line. Example:
## POD_ID=$(kgpid "my-simple-app" | head -1) && echo $POD_ID 

function kcsecret() {
    NAME="$1"
    FILEPATH="${2:-./${NAME}.json}"
    # kubectl delete secret $NAME
    # kubectl create secret generic "${NAME}" --from-file="./_${NAME}.json"
    # kubectl create secret generic "${NAME}" --from-literal="${ITER_NAME}=${ITER_VALUE}"
    SECRET_VALUE_PARAMS=$(jq -r '. | to_entries | .[] | "--from-literal=" + .key + "=" + .value' "$FILEPATH"  | tr "\n" " ")
    eval "kubectl create secret generic ${NAME} ${SECRET_VALUE_PARAMS}"
}

alias noti='f() { osascript -e "display notification \"$2\" with title \"$1\" "; }; f '
alias notis='f() { osascript -e "  display notification \"$2\" with title \"$1\" sound name \"Frog\" "; }; f '
alias kgpid='f() { PODNAME="$1"; k get pods -o name --field-selector=status.phase=Running | grep -E "${PODNAME}" }; f'
alias kgq='k get quota'
alias kge='k get events --sort-by=".lastTimestamp"'
alias kgps='k get pods --sort-by=".status.startTime"'
alias kex='f() { k exec -it "$1" -- /bin/bash; }; f '
alias ksecret='f() { SECRET_NAME="$1"; k get secret $SECRET_NAME -o json | jq -r ".data | map_values(@base64d)" }; f'
alias kplay='k create job playground --image=busybox -- tail -f /dev/null && echo "created job/playground" && sleep 5 && k exec -it job/playground -- /bin/sh'
alias kstop='k delete job/playground'

alias cs="cd ~/project"
alias howto="code ~/project/todolog"
alias dotfiles="code ~/project/dotfiles"

alias dcu="docker compose up"
alias dcd="docker compose down"
alias dcl="docker compose logs"
alias dcb="docker compose build --no-cache --progress=plain"

alias bsserve="f() { npx browser-sync@2.24.7 start -s -f . --no-notify --host $(ipconfig getifaddr en0) --port ${1:-9000} --ui-port ${2:-9001} }; f "

# Convert huge .mov demo files to more transportable animations
alias demo_webp='webp_gen() { local input=${1:-$(ls -t ~/Screenshots/*.mov 2>/dev/null | head -1)}; ffmpeg -y -i "$input" -loop 1 -an -vf scale=750:-2 -r 24 ~/output.webp; }; webp_gen'
alias demo_gif='gif_gen() { local input=${1:-$(ls -t ~/Screenshots/*.mov 2>/dev/null | head -1)}; ffmpeg -y -i "$input" -vf scale=750:-2 -r 24 ~/output.gif; }; gif_gen'
alias demo_hqgif='hqgif_gen() { local input=${1:-$(ls -t ~/Screenshots/*.mov 2>/dev/null | head -1)}; ffmpeg -y -i "$input" -vf "fps=24,scale=750:-2,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" ~/output.gif; }; hqgif_gen'
alias notify='alias-custom-notification'

function alias-custom-notification() {
    osascript -e "display notification \"${2//\"/\\\"}\" with title \"${1//\"/\\\"}\"";
}


export FAFF_MODEL="qwen2.5-coder:3b"
# export FAFF_MODEL="qwen3:8b"

# kube-ps1 config
export KUBE_PS1_PREFIX=''
export KUBE_PS1_SUFFIX=''
# kube-ps1 old version config
export KUBE_PS1_COLOR_SYMBOL="%F{blue}"
export KUBE_PS1_COLOR_CONTEXT="%F{173}"
export KUBE_PS1_COLOR_NS="%F{69}"
# kube-ps1 config newer version config
export KUBE_PS1_SYMBOL_COLOR="blue"
export KUBE_PS1_CTX_COLOR="173"
export KUBE_PS1_NS_COLOR="69"
PROMPT='$(kube_ps1) '$PROMPT


# vi-mode plugin settings
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode
# MODE_INDICATOR="%F{white}+%f"
# INSERT_MODE_INDICATOR="%F{yellow}+%f"
PROMPT="\$(vi_mode_prompt_info) $PROMPT"
RPROMPT="$RPROMPT \$(vi_mode_prompt_info)"

HISTSIZE=10000000
SAVEHIST=10000000

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

function devproxy() {
  TOGGLE=${1:-on}
  NETWORKSERVICE=${2:-"Wi-fi"}
  networksetup -setwebproxystate "$NETWORKSERVICE" "$TOGGLE";
  networksetup -setsecurewebproxystate "$NETWORKSERVICE" "$TOGGLE";
  echo "HTTP and HTTPS proxy turned $TOGGLE for $NETWORKSERVICE"
}

function toolbar_notify() {
  local EVENT_NAME="notification_update"
  local MESSAGE="${1:-}"
  
  if [[ -z "$MESSAGE" ]]; then
    echo "Usage: toolbar_notify <message>"
    return 1
  fi

  sketchybar --trigger "$EVENT_NAME" VAR="$MESSAGE"
}

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# set up smart folder navigation
eval "$(zoxide init zsh)"
_c() {
  [ $# -eq 0 ] && zoxide query --list --score || z "$@"
}
compdef c=_c

export PATH="$HOME/.local/bin:$HOME/scripts:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
# zprof # add this for profiling startup time