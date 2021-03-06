#!/bin/bash

DOTFILES_DIRECTORY="`pwd`"
VSCODE="${HOME}/.config/Code/User"
TEMP="${HOME}/.tmpdotfiles"

linkhome() {
    cp "${HOME}/${2}" "$TEMP" 2>/dev/null
    # Force create/replace the symlink.
    ln -fs "${DOTFILES_DIRECTORY}/${1}" "${HOME}/${2}"
}

linkvscode(){
    # Force create/replace the symlink.
    ln -fs "${DOTFILES_DIRECTORY}/${1}" "${VSCODE}/${2}"
}

printf "Create Symlinks with backup.\n"
mkdir -p $TEMP
# Create the necessary symbolic links between the `.dotfiles` and the appropriate directory.
# The `bash_profile` sources other files directly from the `dotfiles` repository.
linkhome "shell/.bashrc"             ".bashrc"
linkhome "shell/.bash_profile"       ".bash_profile"
linkhome "git/.gitattributes"        ".gitattributes"
linkhome "git/.gitignore"            ".gitignore"
linkhome "git/.gitconfig"            ".gitconfig"
linkhome "vim/.vimrc"                ".vimrc"
mkdir -p ~/.global-modules
linkhome "npm/.npmrc"                ".npmrc"
linkvscode "vscode/keybindings.json" "keybindings.json"
linkvscode "vscode/settings.json"    "settings.json"
linkvscode "vscode/snippets/"        "snippets"

