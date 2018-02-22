#!/bin/bash

# Projects
alias cs="cd ~/project"
alias howto="code ~/project/todolog"
alias dotfiles="code ~/project/dotfiles"

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Update/reload bash_profile
alias bashreload="source ~/.bash_profile"

# Open the last command with authority
alias please='sudo $(fc -ln -1)'
