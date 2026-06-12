#!/bin/bash
brew bundle dump --file="$(dirname "$0")/Brewfile" --force
"$(dirname "$0")/sort.sh"
