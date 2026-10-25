---
name: backlog
description: Turn a raw brain dump of project improvements into a traceable, dependency-ordered backlog, then execute it one task at a time with verification until every item is done or explicitly dropped. Resumes automatically if a backlog exists.
argument-hint: "[agent] [lean] [silent] [yolo] [parallel=N] [paste brain dump | status | resume | audit | clear | clear all | list [all] | todo-sync [path]]"
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Edit Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch *) Bash(git switch *) Bash(git add *) Bash(git commit *) Bash(git show *) Bash(date +%Y%m%d-%H%M) Bash(git remote *) Bash(mkdir -p docs/backlog) Agent AskUserQuestion
---

# Backlog orchestrator

You turn an unstructured improvement dump into finished, verified work. You never lose an item.
State lives in files, not in conversation memory.

## Live context

Git status:
!`git status --short --branch 2>/dev/null || echo "not a git repo"`

Raw input: $ARGUMENTS

**Execution mode** (parse first):
- The input may start with the literal flag words `agent`, `lean`, `silent`, `yolo` and/or `parallel=N`, in any order. Strip them; the rest is the input for everything below (a dump, `resume`, empty, ...).
- `agent` -> AGENT mode. `agent` + empty with an existing backlog = resume in AGENT mode.
- `lean` -> LEAN mode (token saver, for when the daily limit is approaching). It includes everything AGENT mode does, so `lean` alone is enough; `agent lean` is the same.
- `silent` -> no per-task progress lines (see PHASE 3 step 7). Combines with any mode, alone or with `agent`/`lean`; alone it means MAIN mode.
- `yolo` -> the planner decides and assumes instead of asking: skips the CLARIFY step and uses the "decide, note the assumption in LOG.md" rule (Hard rules). Independent of the execution mode; combines with any flag. Only meaningful at intake and mid-run, so it is not offered at approval; pass it again on resume to keep it.
- `parallel=N` (N >= 1) -> at most N subagents run at the same time in AGENT mode. Default 1 (strictly one agent at a time). `N` > 1 implies AGENT mode; in MAIN mode there is nothing to parallelize, so it has no effect.
- Default (no `yolo`): the planner assumes nothing and asks (CLARIFY step in PHASE 1; mid-run rule in Hard rules).
- No mode flag -> MAIN mode (default). The input is used as is.
- Flags can also be given when approving the plan (PHASE 2, e.g. `go lean silent parallel=3`); they then apply to the execution that follows and override the ones from the invocation.
- The mode applies to this invocation only. It is not stored; pass the flag again on resume to keep using it.
- `status`, `list`, `audit`, `clear`, `clear all`, `todo-sync` ignore the mode, except `todo-sync` followed by execution, which uses it.

User input: the raw input minus the leading flag words.

Existing backlog: Read `docs/backlog/BACKLOG.md`. If it does not exist, the backlog is NONE.

## Mode selection

- Backlog is NONE and input is non-empty -> PHASE 1 (intake).
- Backlog exists and input is empty or "resume" -> PHASE 3 (execute) from the first non-done task.
- Input is "status" -> print the status table only. Change nothing.
- Input is "audit" -> PHASE 4 only.
- Input starts with "list" -> LIST (below). Change nothing.
- Input is "clear" -> CLEAR (below). Change nothing else.
- Input is "clear all" -> CLEAR ALL (below). Change nothing else.
- Input starts with "todo-sync" -> TODO SYNC (below), then continue as for a new dump.
- Backlog exists and input is a new dump -> OVERLAPPING DUMPS (below).
- Backlog is NONE and input is empty -> ask the user to paste the dump. Stop.

## Files (single source of truth)

- `docs/backlog/inbox.md`: the verbatim raw dump. Append-only: dumps are added at the end, existing text is never edited. Each fragment gets an ID: I-01, I-02, ...
- `docs/backlog/BACKLOG.md`: status table plus task specs.
- `docs/backlog/LOG.md`: append-only record of what was done per task.
- `docs/backlog/ARCHIVE.md`: `done` task rows and specs moved out by `clear`. Created on first clear. Only finished work lives here.
- `docs/backlog/ABANDONED.md`: ideas that will not be done (`dropped` tasks, REJECTED fragments). Append-only, one entry per idea: `T-xx / I-xx  title  (date -u)  reason  [original spec kept below]`. Created on first entry. Written when the task is set to `dropped` (or the fragment rejected), not only on `clear`.

Create `docs/backlog/` if missing. These files are working state: never stage or commit them (status updates would otherwise need a commit per task, and a task's own hash can't be inside itself).

**Setup (run first in every mode that writes, i.e. everything except `status`, `list`, `audit`; idempotent, no prompt):**
1. `ex=$(git rev-parse --git-path info/exclude)`; if `docs/backlog/` is not already a line in `$ex`, append it (`mkdir -p "$(dirname "$ex")"`). Never edit `.gitignore` for this, and never commit anything for it. This is what keeps the folder out of `git status` without touching a tracked file.
2. `git ls-files docs/backlog` : if it prints anything, those files are already tracked (an exclude entry does not untrack them). Do not untrack or commit on your own; tell the user in one line and give the command: `git rm -r --cached docs/backlog` (then a commit of their choosing). Until then, still never stage them.
3. If the user keeps the files elsewhere (for example `/tmp/backlog`), use that path for all three files instead and skip the exclude step.

## LIST

Read-only. Print the current backlog items grouped by status in this order: in-progress, blocked, todo, done, dropped (skip empty groups). One line per task: `T-xx  [size]  title  (deps: T-yy)  [commit]`. Then, under "Open fragments", list inbox fragments with outcome UNCLEAR or CONFLICT (`I-xx  excerpt`). With `list all`, also include tasks from `ARCHIVE.md` (done) and `ABANDONED.md` (dropped). If the backlog is NONE, say so. No narration.

## CLEAR

Archive finished work so `BACKLOG.md` only shows what is left. Nothing is deleted.

1. Move every `done` row from the Status table, together with its `### T-xx` spec, to the end of `ARCHIVE.md` (keep the commit hash, add the clear date from `date -u`). Only `done` tasks are archived; never archive `todo`, `in-progress`, `blocked` or `dropped`.
2. `dropped` rows: move the row and spec to `ABANDONED.md` (if not already recorded there, add the entry with the reason from LOG.md or "no reason recorded"), then remove them from `BACKLOG.md`. They are not archived as finished work.
3. Leave `todo`, `in-progress` and `blocked` tasks untouched. If a remaining task depends on an archived `done` task, keep the Depends entry; archived `done` counts as satisfied. A dependency on a `dropped` task stays unsatisfied: mark that dependent `blocked` and ask.
4. Leave the Traceability table, `inbox.md` and `LOG.md` untouched (the Task column still points to archived/abandoned IDs).
5. Report in one line: N archived, K abandoned, M remain. If nothing was `done` or `dropped`, say so and change nothing.

### CLEAR ALL (`clear all`)

Empties the backlog completely. Nothing is deleted and no code is touched.

1. `done` rows and specs -> `ARCHIVE.md`, as above.
2. Every other row (`todo`, `in-progress`, `blocked`, `dropped`) with its spec -> `ABANDONED.md`, keeping the status it had (`abandoned from: todo`, ...) and reason: the LOG.md reason for `dropped`/`blocked`, else "backlog cleared". For `in-progress`, note any uncommitted changes in the tree and leave them alone (never stash, restore, or reset).
3. `BACKLOG.md` keeps its header, an empty Status table and the Traceability table. Fragments of abandoned tasks stay in the Traceability table, Task column unchanged.
4. T-IDs and I-IDs are never reused afterwards (a new dump continues from the highest ever used).
5. Report in one line: N archived, K abandoned. Run `clear all` only when the input is exactly that; a bare `clear` never abandons open work.

PHASE 4 and `status` must also read `ARCHIVE.md` and `ABANDONED.md` when checking that every fragment is accounted for.

## TODO SYNC (explicit opt-in only)

`TODO.md` is never read, written, or used as intake unless the input starts with `todo-sync`. Every other mode ignores it.

1. Read `TODO.md` at the repo root (or the path given after `todo-sync`). If missing, say so and stop.
2. Collect unfinished items: unchecked checkbox lines (`- [ ] ...`, nested ones included) that carry no `[backlog:...]` tag. Already tagged lines are skipped, so re-running is safe. If none, report that and stop.
3. Treat the collected lines as a new dump: save them verbatim to `inbox.md` as new fragments, then run PHASE 1 for them (the approval gate still applies).
4. After the plan is written, tag each source line in `TODO.md` in place, appending ` [backlog:T-03]` (several tasks: `[backlog:T-03,T-04]`). A fragment that is not a TASK gets `[backlog:I-05 UNCLEAR]` (or MERGED/REJECTED/CONFLICT). Change nothing else in the line or file.
5. Ticking: whenever a task becomes `done`, find lines tagged with its ID; flip `- [ ]` to `- [x]` only when every task ID on that line is `done` or `dropped`. Lines tagged with a non-TASK outcome are never ticked. Untagged lines are never touched.
6. `TODO.md` edits are working state like `docs/backlog/`: never stage them in task commits. Mention in the final report which lines were tagged and ticked.

## OVERLAPPING DUMPS (second and later dumps)

A new dump can arrive at any time (`/backlog <dump>`): before approval, mid-run, with blocked tasks, after a `clear`. It extends the backlog; it never restarts or rewrites it. Nothing is implemented in the intake turn.

1. **Append** the dump to `inbox.md` under a `## Dump N (<date -u>)` heading. Fragment IDs continue from the highest I-ID ever used (inbox is append-only, so never reuse).
2. **Classify** only the new fragments (same outcomes as PHASE 1), checking against ALL existing fragments, tasks and specs, including `ARCHIVE.md`. Same idea as an existing fragment -> MERGED (name it; if that task is `done`, say so and don't recreate it).
3. **Place** each new TASK fragment:
   - Fits an existing task that is still `todo`: add the fragment to that task's Source and adjust its spec. Say so in the delta.
   - Fits a task that is `in-progress`, `done` or `blocked`: never touch that task. Create a new task; add it to Depends on the old one if it builds on it.
   - Otherwise: new task. IDs continue from the highest T-ID ever used (archive included).
   - Contradicts an existing `todo` spec or the codebase: CONFLICT, ask.
   - Unless `yolo`: run the CLARIFY step (PHASE 1) for the new fragments before placing them.
4. **Order**: re-sort only `todo` tasks (dependencies first, then value/effort). Never reorder or change `in-progress`, `done`, `dropped` rows, their IDs, statuses, or commit hashes.
5. **Update** `BACKLOG.md`: add rows and specs, add traceability rows. Remove nothing.
6. **Approval**: tasks already approved stay approved. Present only the delta, marked NEW / CHANGED (a `todo` task that gained fragments), plus open questions. If the original plan was never approved, this approval covers the whole plan.
7. **After approval** (or on `/backlog resume`), execution continues from the first runnable `todo` task. The branch stays the one recorded in `Branch:`.

If a run is in progress, the dump is handled once the current turn ends; the in-progress task finishes as specified and is not affected by the new dump.

## PHASE 1: Intake (no code changes)

1. Save the raw dump verbatim to `inbox.md`. Split it into atomic fragments with IDs (I-01...). One fragment = one idea. Keep the user's wording.
2. Explore the repo enough to ground the plan: structure, build/test/lint commands, conventions, and the files each idea touches. Read the CLAUDE.md files. Detect the real verification commands. Never invent them.
3. Classify every fragment into exactly one outcome (unless `yolo`, do this, then run the CLARIFY step below before grouping into tasks):
   - TASK: becomes or joins a task.
   - MERGED: duplicate of another fragment (name it).
   - CONFLICT: contradicts another fragment or the codebase (explain).
   - UNCLEAR: cannot be actioned without a decision.
   - REJECTED: harmful or pointless (give the reason).
   Every fragment must appear in the traceability table. Nothing may be silently dropped.
   **CLARIFY step (default; skipped with `yolo`):** do not assume anything, even if the dump looks clear. After exploring and classifying, prepare questions for every real gap or decision point: scope boundaries, intended behavior and edge cases, approach/library choice, naming, acceptance criteria, priority/order, what is explicitly out of scope, and every CONFLICT/UNCLEAR. At least one question per TASK fragment that has any choice in it; if a fragment truly has none, say so in one line instead of inventing a question. Each question: short, 2-4 concrete options with the recommended one first and marked, plus the user's free-text "other". Ask with `AskUserQuestion` (up to 4 questions per call, repeat calls until all are asked); if unavailable, a numbered list. Then STOP and wait. Record the answers in the task specs and in LOG.md under "Decisions (clarify)"; an answered question is not asked again. Answers that raise new gaps get one follow-up round at most. Then continue with step 4.
4. Group TASK fragments into tasks. Rules:
   - A task is one coherent, reviewable change (target: one commit, under about 300 changed lines, under about 8 files).
   - Split anything larger. Do not bundle unrelated ideas.
   - Order by dependency first, then by value/effort. Put risky refactors before features that build on them.
   - Mark tasks that are independent of each other as `parallel-safe`.
5. Write `BACKLOG.md` in the format below.
6. Ask the user only about CONFLICT and UNCLEAR items that block planning. Batch them into one message with a recommended default for each. Do not ask anything else (unless `yolo`, the CLARIFY step has already asked everything).
7. STOP and present: the task list (ID, title, size, depends-on), the traceability summary, and the open questions. End with one line: `Reply go [agent] [lean] [silent] [parallel=N] to run (current: <active flags or none>)`. Wait for approval. Do not implement anything in this turn.

### BACKLOG.md format

```
# Backlog
Branch: <branch>   Created: <date>   Verify: <real commands>

## Status
| ID | Title | Size | Depends | Status | Commit |
|----|-------|------|---------|--------|--------|
| T-01 | ... | S/M/L | - | todo | |

Status values: todo | in-progress | blocked | done | dropped
Setting `dropped` (or rejecting a fragment) also appends an entry with the reason to `ABANDONED.md`.

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

Proceed to execution only after the user approves (e.g. "go", "approved", "looks good") or amends the plan. The approval reply may carry the flag words `agent`, `lean`, `silent`, `parallel=N` (e.g. `go lean silent`); strip them and use them as the execution mode, replacing the invocation's flags (a reply with none keeps the invocation's). Apply amendments to `BACKLOG.md` first, then continue. If the user wants a different execution style (all tasks, N tasks, or one at a time), follow it. Default: run all approved tasks sequentially, stopping on any failure.

## PHASE 3: Execute (one task at a time)

Confirm repo and branch first (`git branch --show-current`, `git remote -v`). If on main/master, create one work branch for the whole backlog, named `backlog/<YYYYMMDD-HHMM>` (local date and time from `date +%Y%m%d-%H%M`, never hand-typed), never derived from a task or topic. Record it in the `Branch:` header of BACKLOG.md; on resume or after a new dump, reuse that branch. If the name already exists and isn't the recorded one, append `-2`, `-3`. Never commit to main/master. Respect uncommitted changes already in the tree: never stash, restore, or reset them, and stage only the task's own files by path (never `git add -A`). If unrelated uncommitted changes overlap the task's files, mark the task `blocked` and ask.

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
7. Set status to `done` with the commit hash. Unless `silent`, immediately emit one plain line: `[<done>/<total>] T-03 done  <short hash>  <title>` (`<done>` counts `done` rows after this task; `<total>` counts Status-table rows that are not `dropped`). A task set to `blocked` gets `[<done>/<total>] T-03 blocked  <one-line reason>`. Nothing else per task; no summary until the end. Append to LOG.md: files changed, commands run and results, deviations from the plan. If the task was synced from `TODO.md`, apply the ticking rule from TODO SYNC.
8. If the task invalidated an assumption in later tasks, update those specs now and note it in LOG.md.

### Execution by mode

**MAIN mode (default):** implement and verify in the main thread. Spawn a subagent only for read-heavy investigation (broad searches, reading many files) so the main context stays focused, or when a task is clearly too big for the main context. Model rule below applies to any agent spawned.

**AGENT mode:** every task's implementation is delegated to a subagent, to save main-thread tokens and run independent work in parallel. The main thread only orchestrates.
1. Pick the runnable tasks (status `todo`, all dependencies `done`). Group them into a batch: tasks marked `parallel-safe` whose Scope files do not overlap run together in one message (several Agent calls at once), but never more than `parallel=N` agents at once (default 1: every task runs alone, in order); anything else runs alone, in order. If more than N tasks are eligible, take the first N in task order and start the rest in later batches.
2. Per task, set `in-progress`, then spawn a fresh `general-purpose` agent (not `fork`: it ignores the model override). Its prompt is self-contained: the full task spec, the repo conventions and verify commands from the `BACKLOG.md` header, and these constraints: touch only the Scope files, do not commit or stage, do not touch `docs/backlog/`, report files changed and the commands it ran with results.
3. When agents return, the main thread does steps 4-8 above itself, task by task: run verification and read the real output, self-review `git diff` limited to that task's paths, stage by path, commit, set `done`, write LOG.md. Never trust the agent's own "tests pass"; re-run.
4. If verification of a parallel task fails because of another task's uncommitted changes in the shared tree, commit the others first, then re-verify. A genuine failure goes back to a new agent run (counts toward the 3 attempts, with escalation below).
5. Blocked agents or environment errors follow the same blocked rules as MAIN mode.

**Model for spawned agents (all modes):** set the Agent `model` from the task's Size:
- S -> `haiku`, M -> `sonnet`, L -> `sonnet`. In LEAN mode: S -> `haiku`, M -> `haiku`, L -> `sonnet`.
- Never above `sonnet`, whatever model the main thread runs on. Read-only investigation agents: `haiku` for simple lookups, else `sonnet`.
- An optional `Model:` line in the task spec overrides the default, still capped at `sonnet`.
- If a `haiku` attempt fails verification, the next attempt uses `sonnet`. There is no escalation beyond `sonnet`.

**LEAN mode (save tokens):** AGENT mode plus the following. The goal is the fewest tokens on the main model without ever lowering the bar for "done".
- Always delegate implementation (no main-thread coding, no investigation agents). Cheapest models per the table above; `haiku` retries on `sonnet` once, as usual.
- Intake: classify every fragment as usual (traceability stays complete), but explore the repo only as far as needed: read the CLAUDE.md files and the build/test config, then only the files a task names. No broad searches.
- Agent prompts are minimal: the task spec, verify commands and constraints, nothing else. Ask the agent to reply in under 10 lines.
- Main thread per task: re-run only the task's verification plus the project's fast checks (lint/typecheck); run the full test suite once, at the end. Review the diff once (staged, by path) instead of per criterion. Commit, set `done`.
- LOG.md: one line per task (commit, files, result). No narration; reports are the status table plus exceptions.
- Don't re-read files you just wrote or specs already in context. Don't print command output unless it failed.
- Checkpoint after every task: BACKLOG.md and LOG.md current and the commit made, so a limit hit between tasks loses nothing. If you start a task and can't finish it, leave it `in-progress` with a LOG.md note saying what is left; `/backlog resume` (or `/backlog lean`) continues from there.
- Still never mark a task `done` without its verification run and passed; anything skipped goes under "Not verified" in the final audit.

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
- `clear` only archives `done` tasks. Abandoned ideas go to `ABANDONED.md`, never `ARCHIVE.md`.
- Never delete or reword inbox fragments. Never remove rows from the traceability table.
- Never expand scope silently. New work becomes a new fragment.
- Never push, force-push, merge the backlog branch into main/master, rewrite history, or touch files outside the repo.
- By default, ask instead of assuming, at intake and mid-run (a task whose spec leaves a choice open is set `blocked` with the question and options, and the run continues with other tasks). With `yolo`: decide, state the assumption in LOG.md, and continue.
- Keep reports short: status table, then exceptions. No narration of routine steps; the one-line per-task progress is the only per-task output (suppressed by `silent`).
