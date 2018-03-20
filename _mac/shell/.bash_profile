# Run VSCode commands: "Shell Command: Install 'code' command in PATH"
# export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
# code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

# git helper
source ~/.git-prompt.sh
# for more info, http://git.kernel.org/?p=git/git.git;a=blob;f=contrib/completion/git-completion.bash;hb=HEAD
# __git_ps1 flags
# show * if there are untracked changes and + if staged and uncommitted changes
export GIT_PS1_SHOWDIRTYSTATE=1
# show $ if there are stashed changes
export GIT_PS1_SHOWSTASHSTATE=1
# show % if there are untracked files
export GIT_PS1_SHOWUNTRACKEDFILES=1
# show < if there are unpulled changes, > if there are unpushed changes, or <> if there are both, up to date "="
export GIT_PS1_SHOWUPSTREAM=1
# \j  - the  number of jobs currently managed by the shell
# for more info: http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html
PS1='$(__git_ps1 "(%s) ")[\j]'$PS1

. $HOME/.bash_aliases

export PATH="$PATH:$HOME/.global-modules/bin"

export CLICOLOR=1
