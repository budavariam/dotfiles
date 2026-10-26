---
description: Bring the current branch up to date with a base branch without losing uncommitted work
---

Sync the current branch with a base branch. $ARGUMENTS may name the base (e.g. "development") and the method ("rebase" or "merge"). Default base: the repo's default branch; default method: merge, unless the branch is unpushed and the project rebases.

1. Confirm repo and branch: `git branch --show-current`, `git remote -v`, `git status --short`. If I named a branch, use it.
2. If there are uncommitted changes, do NOT stash, restore or reset them. Treat them as intentional. Either work with them in place (merge/rebase refuse a dirty overlap and tell you), or stop and ask.
3. `git fetch`, then show what is incoming: `git log --oneline HEAD..origin/<base>` and the files touched by both sides.
4. Merge or rebase onto `origin/<base>`.
5. On conflicts: list each conflicted file, resolve by reading both sides (keep intent of both; don't blindly take one), and explain any non-trivial resolution. Never use `-X ours/theirs` or `--strategy` shortcuts without asking.
6. After the sync, run `git log --oneline -10` and `git status`, and tell me whether the branch is now ahead, behind, or diverged from its upstream.
7. Do not push, and do not force-push after a rebase, without explicit confirmation.
8. Stale worktree check: if the work involves worktrees, `git worktree list` and say which ones are behind the base.
