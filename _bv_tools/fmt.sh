#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -n "${1:-}" ]]; then
  cargo fmt -p "$1"
else
  cargo fmt --all
fi
