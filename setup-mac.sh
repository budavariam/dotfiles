#!/bin/bash

FOLDER_VSCODE="${HOME}/Library/Application Support/Code/User"
FOLDER_TEMP="${HOME}/.tmpdotfiles/"

if ! command -v stow &>/dev/null; then
  echo "stow is not installed. Installing it along other brew dependencies..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  pushd "_mac/brew" || exit 1
    brew bundle install --file="$(pwd)/Brewfile"
  popd || exit 1
fi

# Use stow to create symlinks
pushd "_mac" || exit 1
  stow -vt ~ aerospace
  stow -vt ~ git
  # stow -vt ~ iterm2 # need to set iterm2 manually
  stow -vt ~ screen
  stow -vt ~ scripts
  stow -vt ~ shell
  stow -vt ~ sketchybar
  stow -vt ~ talon
  stow -vt ~ tmux
  stow -vt ~ zsh
  stow -vt "${FOLDER_VSCODE}" vscode
  stow -vt ~ wezterm
popd || exit 1
stow -vt ~ claude
stow -vt ~ git
stow -vt ~ npm
stow -vt ~ vim

printf "Dotfiles setup complete. Backups of replaced files are stored in %s\n", "${FOLDER_TEMP}"
