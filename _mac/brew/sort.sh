#!/bin/bash
FILE="$(dirname "$0")/Brewfile"
sections=$(awk '{print $1}' "$FILE" | sort -u | awk '/^tap$/{next} {print}')
{ awk '$1=="tap"' "$FILE" | sort; for section in $sections; do awk -v s="$section" '$1==s' "$FILE" | sort; done; } > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
