#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -n "${1:-}" ]]; then
  cargo clippy --all-targets -p "$1" -- -D warnings
else
  cargo clippy --all-targets -- -D warnings
fi
