#!/bin/bash

# Run this script line by line on a fresh mac to get some useful tools.

#install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# wget
brew install wget
# ack-grep
brew install ack
# tree
brew install tree
# midnight commander
brew install mc
# fzf
brew install fzf
# ag
brew install the_silver_searcher

# install cask to install other programs
brew tap homebrew/cask
# kdiff3
brew install kdiff3 --cask
# copyq
brew install copyq --cask
# chrome
brew install google-chrome --cask
# meld
brew install meld --cask
# iterm 2
brew install iterm2 --cask
# p4merge
brew install p4v --cask
# gnu sed
brew install gnu-sed
brew install less

brew install git-delta

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# zsh autosuggestion plugin
pushd ./zsh/custom/plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions 
    git clone https://github.com/Aloxaf/fzf-tab
popd

brew install bash
# sudo vim /etc/shells
# add line to the file with the proper version number to whitelist in mac: /usr/local/Cellar/bash/5.0.0/bin/bash

## ZSH addons

git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

