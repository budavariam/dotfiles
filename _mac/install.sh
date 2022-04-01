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
# p4merge
brew cask install p4v
# gnu sed
brew install gnu-sed

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# zsh autosuggestion plugin
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/Aloxaf/fzf-tab ~ZSH_CUSTOM/plugins/fzf-tab

brew install bash
# sudo vim /etc/shells
# add line to the file with the proper version number to whitelist in mac: /usr/local/Cellar/bash/5.0.0/bin/bash