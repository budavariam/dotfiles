#!/bin/bash

# Run this script on a fresh mac to get some useful tools

#install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install wget

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
# ack-grep
brew install ack
# tree
brew install tree
