#!/bin/bash
set -e

# Prerequisites for the neovim config.
# Run this before: stow nvim

# neovim
brew install neovim

# ripgrep: telescope live_grep / grep_string
brew install ripgrep

# fd: faster file finding for telescope
brew install fd

# make: builds telescope-fzf-native on first lazy.nvim sync
xcode-select --install 2>/dev/null || true

# cargo: required for tree-sitter-cli
if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# tree-sitter-cli: compiles parsers for :TSInstall
# (brew install tree-sitter only installs the library, not the CLI)
cargo install tree-sitter-cli

echo ""
echo "Done. Next steps:"
echo "  1. stow nvim"
echo "  2. Open Neovim — lazy.nvim will auto-install plugins on first launch"
echo "  3. Install language parsers (repeat for each language you use):"
echo "       :TSInstall rust"
echo "       :TSInstall go"
echo "       :TSInstall python"
echo "       :TSInstall lua"
echo "     Or install all at once: :TSInstall all"
