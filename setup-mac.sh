#!/bin/bash

DOTFILES_DIRECTORY="${PWD}"
VSCODE="${HOME}/Library/Application Support/Code/User"
TEMP="${HOME}/.tmpdotfiles/"

linkhome() {
    cp "${HOME}/${2}" "$TEMP" 2>/dev/null
    # Force create/replace the symlink.
    ln -fs "${DOTFILES_DIRECTORY}/${1}" "${HOME}/${2}"
}

linkvscode(){
    # Force create/replace the symlink.
    ln -fs "${DOTFILES_DIRECTORY}/${1}" "${VSCODE}/${2}"
}

printf "Create Symlinks\n"
mkdir -p $TEMP
# Create the necessary symbolic links between the `.dotfiles` and the appropriate directory.
# The `bash_profile` sources other files directly from the `dotfiles` repository.
linkhome "_mac/shell/.git-prompt.sh"      ".git-prompt.sh"
linkhome "_mac/shell/.bash_aliases"       ".bash_aliases"
linkhome "_mac/shell/.bash_profile"       ".bash_profile"
linkhome "_mac/shell/.bashrc"             ".bashrc"
linkhome "_mac/git/.gitconfig.local"      ".gitconfig.local"
linkhome "_mac/zsh/.zshrc"                ".zshrc"
linkhome "_mac/zsh/custom/themes"         ".oh-my-zsh/custom"
linkhome "_mac/zsh/custom/plugins"        ".oh-my-zsh/custom"
linkhome "_mac/tmux/.tmux.conf"           ".tmux.conf"
linkhome "_mac/screen/.screenrc"          ".screenrc"
linkhome "git/.gitattributes"             ".gitattributes"
linkhome "git/.gitignore"                 ".gitignore"
linkhome "git/.gitconfig"                 ".gitconfig"
linkhome "vim/.vimrc"                     ".vimrc"
mkdir -p ~/.global-modules
linkhome "npm/.npmrc"                     ".npmrc"
linkvscode "_mac/vscode/keybindings.json" "keybindings.json"
linkvscode "_mac/vscode/settings.json"    "settings.json"
linkvscode "vscode/snippets/"             "snippets"
