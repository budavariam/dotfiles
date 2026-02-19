#!/usr/bin/env bash

input=$(cat)

# Extract fields from JSON input
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "."')

# Current folder basename from working directory
folder=$(basename "$cwd")

# Git branch (skip optional locks to avoid blocking)
git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
if [ -z "$git_branch" ]; then
  git_section="git:?"
else
  git_section="git:${git_branch}"
fi

# Context progress bar (10 chars wide)
if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct" | awk '{printf "%d", int($1 / 10 + 0.5)}')
  [ "$filled" -lt 0 ] 2>/dev/null && filled=0
  [ "$filled" -gt 10 ] 2>/dev/null && filled=10
  empty=$((10 - filled))
  bar=""
  for i in $(seq 1 "$filled"); do bar="${bar}█"; done
  for i in $(seq 1 "$empty"); do bar="${bar}░"; done
  pct_display=$(echo "$used_pct" | awk '{printf "%.0f%%", $1}')
  context_section="${bar} ${pct_display}"
else
  context_section="░░░░░░░░░░ -"
fi

# Subagent info: shown only when the agent field is present in the JSON input
# Note: Claude Code statusLine JSON does not expose aggregate task/agent counts,
# so the [tasks | agents] section is built from what is available.
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
if [ -n "$agent_name" ]; then
  agent_section=" | [agent: ${agent_name}]"
else
  agent_section=""
fi

# Build the final output
printf "%s | %s | %s | %s%s" "$folder" "$git_section" "$model" "$context_section" "$agent_section"
