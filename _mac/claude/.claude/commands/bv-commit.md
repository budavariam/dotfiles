---
description: Make one clean conventional commit with no LLM attribution; push only if asked
---

Commit the current work. If $ARGUMENTS contains "push", push after committing; otherwise do not push.

1. Confirm the repo and branch: `git branch --show-current`, `git remote -v`. If on the default branch, stop and ask.
2. Run `git status`, `git diff` and `git diff --staged`. Stage only files that belong to the current task; never `git add -A` blindly.
3. Strip local-only debug artifacts from the staged diff before committing: `console.log`, temporary flags, test-only tags (e.g. `tags: ['asd']`), commented-out code, personal editor files. Mention what you stripped.
4. Write ONE commit per logical change, using a scoped conventional commit: `type(scope): short imperative summary`. Match the scopes and style seen in `git log --oneline -15`.
5. No LLM attribution: no `Co-Authored-By`, no "Generated with" lines, no tool mentions in the message.
6. If the work covers several unrelated changes, propose how to split them and wait for confirmation.
7. If the commit is review feedback on an unpushed or own branch commit, amend or squash into the original commit; do not create fixup commits.
8. Never run `git checkout --`, `git restore`, `git stash` or `git reset --hard` on files with uncommitted changes.
9. If pushing: use a plain `git push` (or `--set-upstream` for a new branch). Never force-push without explicit confirmation. If a PR exists, check the CI run afterwards with `gh pr checks` instead of assuming it passed.

Report the commit hash, message, and branch.
