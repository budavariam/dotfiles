#!/bin/bash

declare -r GITHUB_REPOSITORY="budavariam/dotfiles"

declare -r DOTFILES_ORIGIN="git@github.com:$GITHUB_REPOSITORY.git"
declare -r DOTFILES_TARBALL_URL="https://github.com/$GITHUB_REPOSITORY/tarball/master"
declare -r DOTFILES_UTILS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/master/src/os/utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare dotfilesDirectory="$HOME/project/dotfiles"
declare vscode="${HOME}/.config/Code/User/"
declare skipQuestions=false

linkhome() {
    # Create a copy before overwrite.
    cp "${HOME}/${2}" "./tmp/${1}"
    # Force create/replace the symlink.
    ln -fs "${DOTFILES_DIRECTORY}/${1}" "${HOME}/${2}"
}

linkvscode(){
    # Create a copy before overwrite.
    cp "${VSCODE}/${2}" "./tmp/${1}"
    # Force create/replace the symlink.
    ln -fs "${DOTFILES_DIRECTORY}/${1}" "${VSCODE}/${2}"
}

printf "Create Symlinks"
# Create the necessary symbolic links between the `.dotfiles` and `HOME`
# directory. The `bash_profile` sources other files directly from the
# `.dotfiles` repository.
linkhome "shell/.bashrc"             ".bashrc"
linkhome "shell/.bash_profile"       ".bash_profile"
linkhome "git/.gitattributes"        ".gitattributes"
linkhome "git/.gitignore"            ".gitignore"
linkhome "git/.gitconfig"            ".gitconfig"
linkhome "vim/.vimrc"                ".vimrc"
linkvscode "vscode/keybindings.json" "keybindings.json"
linkvscode "vscode/settings.json" "settings.json"


