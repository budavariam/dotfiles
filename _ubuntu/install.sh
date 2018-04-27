#!/bin/bash

# This file might not be suitable to run all at once, but the code can be picked from here, If you do not want to search for all these things in the net.
# If something is not working the installation method might have changed since.

# ack-grep
apt-get install vim
apt-get install ack-grep
apt-get install wget
apt-get install curl

# Install vscode

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt-get update
sudo apt-get install code # or code-insiders

# Install google-chrome

# Add Key
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
# Set repository
echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list
#Install package
sudo apt-get update
sudo apt-get install google-chrome-stable

# In ubuntu1604unity google-chrome can not open links from external applications

vim -es -c '%s/^\(Exec=\/opt\/google\/chrome\/chrome\)$/\1 %U/g' -c wq "$HOME/.local/share/applications/google-chrome.desktop"

# As unfulvio said, the issue is with google-chrome.desktop, and it is missing the %U argument .
# Open file: "$HOME/.local/share/applications/google-chrome.desktop"
# Find the line: "Exec=/opt/google/chrome/chrome"
# Add a space and %U: "Exec=/opt/google/chrome/chrome %U"
# Source: https://askubuntu.com/a/701775/785947
# I have automated it with vim ex mode. Regex match the line and replace it with the added extra 3 characters. Note that the capture group parenthesis has to be escaped.