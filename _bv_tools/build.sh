#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -n "${1:-}" ]]; then
  _bin="target/release/$1"
  if [[ ! -f "${_bin}" ]] || \
     [[ -n "$(find . -name "*.rs" -newer "${_bin}" -not -path "*/target/*" -print -quit 2>/dev/null)" ]]; then
    echo "bv-tools: building $1..." >&2
    cargo build --release -p "$1"
  fi
else
  cargo build --release
fi
