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

# install cask to install other programs
brew tap caskroom/cask
# kdiff3
brew cask install kdiff3
# copyq
brew cask install copyq
# chrome
brew cask install google-chrome
# meld
brew cask install meld
# iterm 2
brew cask install iterm2

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"