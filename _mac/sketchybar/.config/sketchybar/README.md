# SketchyBar AI sessions item

`items/ai.sh` + `plugins/ai.sh` show running AI sessions in the bar (`busy/total`) and a dropdown
(`plugins/ai_sessions.py`). Claude Code rows get a red warning icon (and `!` on the bar item) while
the session **waits for you**: a question (`AskUserQuestion`) or a permission prompt.
Finishing a task or going idle does not count.

## Getting started

Prerequisites: `brew install sketchybar jq terminal-notifier`, and the `claude` / `sketchybar`
stow packages linked (`~/.claude` and `~/.config/sketchybar` point into this repo).

The bar side works out of the box. The Claude side needs hooks in `~/.claude/settings.json`, which is
**gitignored**, so install them once per machine:

```sh
~/.claude/notify.init.sh     # idempotent, safe to re-run; also migrates the old hook layout
sketchybar --reload
```

Then restart running Claude sessions: hooks are read at session start.

## How it works

Per-session flag files in `/tmp/claude-needs-action.d/<session_id>` drive the icon.
`~/.claude/sketchybar-claude-update.sh` sets/clears them and triggers `claude_update`.

| Hook | Action |
|---|---|
| `Notification` → `notify.sh` | on `permission_prompt`: notify + `set-needs-action` (`idle_prompt` only notifies) |
| `PreToolUse` matcher `AskUserQuestion` | notify + `set-needs-action` (before the question is shown) |
| `PostToolUse` (all tools) | `clear-needs-action` (answered / approved) |
| `Stop` | `clear-needs-action` + `refresh` |

Do not clear on `PreToolUse`: hooks run in parallel, so it can wipe the flag the `AskUserQuestion` hook just set.
A denied permission leaves the flag until the next tool call or `Stop`.

## Verify

```sh
jq '.hooks | {PreToolUse, PostToolUse, Notification, Stop}' ~/.claude/settings.json | grep -c sketchybar-claude-update  # expect 4
ls /tmp/claude-needs-action.d/     # a file appears while Claude waits on a question/permission
_mac/tests/run.sh _mac/tests/sketchybar/ai.bats
```

Notifications inside tmux need `reattach-to-user-namespace` (see the note printed by `notify.init.sh`).
