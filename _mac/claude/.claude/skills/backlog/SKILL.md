---
name: backlog
description: Turn a raw brain dump of project improvements into a traceable, dependency-ordered backlog, then execute it one task at a time with verification until every item is done or explicitly dropped. Resumes automatically if a backlog exists.
argument-hint: "[paste brain dump | status | resume | audit | todo-sync [path]]"
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Edit Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch *) Bash(git switch *) Bash(git add *) Bash(git commit *) Bash(git show *) Bash(git remote *) Bash(mkdir -p docs/backlog)
---

# Backlog orchestrator

You turn an unstructured improvement dump into finished, verified work. You never lose an item.
State lives in files, not in conversation memory.

## Live context

Git status:
!`git status --short --branch 2>/dev/null || echo "not a git repo"`

User input: $ARGUMENTS

Existing backlog: Read `docs/backlog/BACKLOG.md`. If it does not exist, the backlog is NONE.

## Mode selection

- Backlog is NONE and input is non-empty -> PHASE 1 (intake).
- Backlog exists and input is empty or "resume" -> PHASE 3 (execute) from the first non-done task.
- Input is "status" -> print the status table only. Change nothing.
- Input is "audit" -> PHASE 4 only.
- Input starts with "todo-sync" -> TODO SYNC (below), then continue as for a new dump.
- Backlog exists and input is a new dump -> append the new items to `inbox.md`, re-run PHASE 1 for the new items only, and keep all existing IDs and statuses.
- Backlog is NONE and input is empty -> ask the user to paste the dump. Stop.

## Files (single source of truth)

- `docs/backlog/inbox.md`: the verbatim raw dump, never edited after saving. Each fragment gets an ID: I-01, I-02, ...
- `docs/backlog/BACKLOG.md`: status table plus task specs.
- `docs/backlog/LOG.md`: append-only record of what was done per task.

Create `docs/backlog/` if missing. These files are working state: never stage or commit them (status updates would otherwise need a commit per task, and a task's own hash can't be inside itself). If the repo doesn't ignore them, add `docs/backlog/` to `.git/info/exclude`, not `.gitignore`.

## TODO SYNC (explicit opt-in only)

`TODO.md` is never read, written, or used as intake unless the input starts with `todo-sync`. Every other mode ignores it.

1. Read `TODO.md` at the repo root (or the path given after `todo-sync`). If missing, say so and stop.
2. Collect unfinished items: unchecked checkbox lines (`- [ ] ...`, nested ones included) that carry no `[backlog:...]` tag. Already tagged lines are skipped, so re-running is safe. If none, report that and stop.
3. Treat the collected lines as a new dump: save them verbatim to `inbox.md` as new fragments, then run PHASE 1 for them (the approval gate still applies).
4. After the plan is written, tag each source line in `TODO.md` in place, appending ` [backlog:T-03]` (several tasks: `[backlog:T-03,T-04]`). A fragment that is not a TASK gets `[backlog:I-05 UNCLEAR]` (or MERGED/REJECTED/CONFLICT). Change nothing else in the line or file.
5. Ticking: whenever a task becomes `done`, find lines tagged with its ID; flip `- [ ]` to `- [x]` only when every task ID on that line is `done` or `dropped`. Lines tagged with a non-TASK outcome are never ticked. Untagged lines are never touched.
6. `TODO.md` edits are working state like `docs/backlog/`: never stage them in task commits. Mention in the final report which lines were tagged and ticked.

## PHASE 1: Intake (no code changes)

1. Save the raw dump verbatim to `inbox.md`. Split it into atomic fragments with IDs (I-01...). One fragment = one idea. Keep the user's wording.
2. Explore the repo enough to ground the plan: structure, build/test/lint commands, conventions, and the files each idea touches. Read the CLAUDE.md files. Detect the real verification commands. Never invent them.
3. Classify every fragment into exactly one outcome:
   - TASK: becomes or joins a task.
   - MERGED: duplicate of another fragment (name it).
   - CONFLICT: contradicts another fragment or the codebase (explain).
   - UNCLEAR: cannot be actioned without a decision.
   - REJECTED: harmful or pointless (give the reason).
   Every fragment must appear in the traceability table. Nothing may be silently dropped.
4. Group TASK fragments into tasks. Rules:
   - A task is one coherent, reviewable change (target: one commit, under about 300 changed lines, under about 8 files).
   - Split anything larger. Do not bundle unrelated ideas.
   - Order by dependency first, then by value/effort. Put risky refactors before features that build on them.
   - Mark tasks that are independent of each other as `parallel-safe`.
5. Write `BACKLOG.md` in the format below.
6. Ask the user only about CONFLICT and UNCLEAR items that block planning. Batch them into one message with a recommended default for each. Do not ask anything else.
7. STOP and present: the task list (ID, title, size, depends-on), the traceability summary, and the open questions. Wait for approval. Do not implement anything in this turn.

### BACKLOG.md format

```
# Backlog
Branch: <branch>   Created: <date>   Verify: <real commands>

## Status
| ID | Title | Size | Depends | Status | Commit |
|----|-------|------|---------|--------|--------|
| T-01 | ... | S/M/L | - | todo | |

Status values: todo | in-progress | blocked | done | dropped

## Traceability (every inbox fragment accounted for)
| Fragment | Excerpt | Outcome | Task / reason |
|----------|---------|---------|---------------|
| I-01 | "..." | TASK | T-01 |

## Tasks
### T-01 <title>
- Source: I-01, I-04
- Goal: <one sentence, observable outcome>
- Scope: <files/modules>
- Non-goals: <what NOT to touch>
- Approach: <3-6 concrete steps>
- Acceptance criteria: <testable checklist>
- Verification: <exact commands, plus manual check if relevant>
- Risks: <...>
```

## PHASE 2: Approval gate

Proceed to execution only after the user approves (e.g. "go", "approved", "looks good") or amends the plan. Apply amendments to `BACKLOG.md` first, then continue. If the user wants a different execution style (all tasks, N tasks, or one at a time), follow it. Default: run all approved tasks sequentially, stopping on any failure.

## PHASE 3: Execute (one task at a time)

Confirm repo and branch first (`git branch --show-current`, `git remote -v`). Create a work branch if on main/master: `backlog/<short-slug>`. Never commit to main/master. Respect uncommitted changes already in the tree: never stash, restore, or reset them, and stage only the task's own files by path (never `git add -A`). If unrelated uncommitted changes overlap the task's files, mark the task `blocked` and ask.

Before any package install, check the runtime matches the project's declared version (`.nvmrc`, `.python-version`, etc.); on mismatch, stop and ask.

For each task in order, skipping `done`/`dropped` and tasks whose dependencies are not `done`:

1. Set status to `in-progress` in BACKLOG.md.
2. Re-read the task spec and the files it names. Work ONLY on this task's scope. If you spot something outside it, add it to `inbox.md` as a new fragment (next I-ID) and continue. Do not fix it now.
3. Implement the smallest change that meets the acceptance criteria. Follow existing conventions. Add or update tests for behavior changes.
4. Verify: run the task's verification commands plus the project's lint/build/test commands. Read the actual output.
   - Pass: continue.
   - Blocked by permissions or sandbox (install, network, denied command): do not retry or work around it. Set `blocked`, record the exact error in LOG.md, and follow "Blocked-by-environment report" below.
   - Other failure: fix and retry, at most 3 attempts. Then set `blocked`, record the exact error in LOG.md, and move on to the next task that does not depend on it. Never mark done on a failing or unrun check.
5. Self-review `git diff` against the acceptance criteria, one criterion at a time. Check for scope creep, leftover debug code, and unrelated formatting changes.
6. Stage by path, diff the staged changes, then commit one commit per task with a message referencing the task ID (e.g. `T-03: add retry to HTTP client`). Do not push. If a later review needs changes to an earlier task, amend or squash into it; no fixup commits.
7. Set status to `done` with the commit hash. Append to LOG.md: files changed, commands run and results, deviations from the plan. If the task was synced from `TODO.md`, apply the ticking rule from TODO SYNC.
8. If the task invalidated an assumption in later tasks, update those specs now and note it in LOG.md.

Use a subagent only for read-heavy investigation (broad searches, reading many files) so the main context stays focused. Implement and verify in the main thread.

Context hygiene: if the context becomes large mid-run, finish the current task fully, make sure BACKLOG.md and LOG.md are current, tell the user to run `/compact` or start a fresh session and invoke `/backlog` to resume. All state is on disk.

### Blocked-by-environment report

Never ask whether to proceed and never write a vague line like "you'll need to run the install yourself". Do not pause the run: continue with tasks that don't depend on the blocked one. In the same message, and again in the final report, give each blocker as:

- Blocked task(s) and what the command unblocks (e.g. "T-01; unblocks T-02, T-05 Storybook tasks").
- The exact command in a copyable `! <command>` line, with the real package manager (from the lockfile: `pnpm-lock.yaml` -> `pnpm install`, `package-lock.json` -> `npm install`, `yarn.lock` -> `yarn install`; never guess) and exact package names/versions if it is an add. If the command must run in a subdirectory, prefix `cd <dir> &&`. Check the runtime version first (`.nvmrc` etc.) and include the switch (`nvm use &&`) when needed.
- Why it was blocked, quoting the error in one line (e.g. `ENOTFOUND registry.npmjs.org`: sandbox has no network).
- How to resume: "run it, then `/backlog resume`".

Example: `T-01 blocked: sandbox cannot reach registry.npmjs.org (ENOTFOUND). Unblocks T-02, T-05. Run: ! cd web && nvm use && pnpm install   then: /backlog resume`

## PHASE 4: Final audit (always runs when no `todo` tasks remain)

1. Re-read `inbox.md` and the traceability table. For each fragment, confirm: its task is `done` (verify that the commit exists and touches the expected files), or it is MERGED/REJECTED/dropped with a reason, or it is still open.
2. Run the full project verification once more.
3. Report to the user:
   - Completed: tasks with commits.
   - Blocked: reason and what is needed.
   - Dropped/rejected/unclear: with reasons.
   - New ideas discovered during the work (new inbox fragments).
   - Not verified: anything not run, and why.
   - For UI changes: which page or story to check manually.
4. State plainly whether every original fragment is accounted for. If it isn't, list the gaps.

## Hard rules

- Never claim something is done without having run its verification and seen it pass.
- Never delete or reword inbox fragments. Never remove rows from the traceability table.
- Never expand scope silently. New work becomes a new fragment.
- Never push, force-push, rewrite history, or touch files outside the repo.
- Ask the user only for decisions that change architecture or product behavior. Otherwise decide, state the assumption in LOG.md, and continue.
- Keep reports short: status table, then exceptions. No narration of routine steps.
