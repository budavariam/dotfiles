#!/bin/sh
# Runs the dotfiles test suites (bats-core). See README.md next to this file.
# Usage: _mac/tests/run.sh [bats args or test files]   (default: every suite)
set -eu

DIR=$(cd "$(dirname "$0")" && pwd)

missing=""
for cmd in bats jq python3; do
  command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done
if [ -n "$missing" ]; then
  echo "Missing:$missing"
  echo "Install with: brew install bats-core jq python3"
  exit 1
fi

if [ "$#" -eq 0 ]; then
  set -- --recursive "$DIR"
fi
exec bats "$@"
