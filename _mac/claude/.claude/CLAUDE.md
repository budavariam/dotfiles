## Git Safety

- NEVER run `git checkout --`, `git restore`, `git stash`, or `git reset --hard` on files with uncommitted changes. Assume all uncommitted work is intentional dev hacks the user wants to keep. Ask first.
- Before committing, diff the staged changes and strip local-only debug artifacts (e.g. `tags: ['asd']`, console.log, temporary flags). Commits should be minimal and clean — one logical change per commit.

## Verification Before Claiming

- Do not assert how a system behaves (enums, Redis topology, API refresh semantics, cache invalidation) without reading the code or running a command that proves it. If unverified, say "I need to check" and check.
- Never hand-compute Unix timestamps, dates, or durations — run `date -d @<ts>` / `date -u` instead.
- For any script that greps logs or connects to a service, verify the pattern and port against real output before presenting it as working.

## Workflow Conventions

- When adding a capability to the review wizard or any CLI, wire it as a standalone menu entry/flag in the same change — not just as inline logic in an existing step.
- Never default an assignee/user field to `me`; require an explicit value or resolve it from config.

## Side-Notes During Active Work

While working on a task, the user may mention new feature ideas, bug reports, or code errors that are unrelated to the current task. These are notes for later, not redirections.

- Acknowledge the note briefly (one sentence max).
- Persist it immediately using the memory system (type: `project` for bugs/errors, `feedback` for feature ideas).
- Do NOT investigate, implement, or shift focus to the side-note unless the user explicitly says to switch tasks (e.g. "actually let's do this first", "pause and fix this").
- Resume the current task without further commentary about the side-note.

## Bug Hunting

When the user is investigating a bug:

1. Before writing any code, list the top 3 hypotheses for this bug.
2. For each hypothesis, give the exact command or file+line that would confirm or rule it out.
3. Run those checks and show the raw output.
4. Only after one hypothesis is confirmed by evidence, propose a fix.
5. If the evidence suggests no fix is needed, say so explicitly.

## Tool Version Detection Before Installing

Before running any package install (`npm install`, `pip install`, `uv sync`, `bundle install`, etc.), verify the active runtime version matches the project's declared version. Wrong runtime versions silently produce corrupted or mismatched lock files.

**Check order — first file found wins:**

| Ecosystem | Files to check (in order) | How to verify active version |
|-----------|--------------------------|------------------------------|
| Node.js   | `.nvmrc`, `.node-version`, `package.json#engines.node`, `Dockerfile` `FROM node:X` | `node --version` |
| Python    | `.python-version`, `pyproject.toml#requires-python`, `.tool-versions` `python X`, `Dockerfile` `FROM python:X` | `python --version` |
| Ruby      | `.ruby-version`, `.tool-versions` `ruby X`, `Gemfile` `ruby 'X'` | `ruby --version` |
| Rust      | `rust-toolchain.toml` `channel`, `rust-toolchain` | `rustc --version` |
| Java/JVM  | `.java-version`, `.tool-versions` `java X` | `java --version` |

**Rules:**
- Read the project's version file before installing. If the active version doesn't match, switch it first (`nvm use`, `pyenv shell X`, etc.) before running the install.
- If no version file exists, note the version mismatch risk explicitly before proceeding.
- Never run `npm install` / `uv sync` / `pip install` with a different major version than the project declares — it will regenerate the lock file for the wrong runtime.
- For Dockerfiles, the `FROM` line is the authoritative version; match the host version to it when generating lock files outside the container.
- If a version manager is not installed or the required version is not available, stop and ask rather than proceeding with the wrong version.

## Commands

### Rust / TypeScript Checks

- Rust: run `cargo fmt`, `cargo clippy`, and `cargo check` from the crate root (`cd` to the correct directory first). If results look stale, `touch` the changed file or use `cargo clean -p <crate>` before retrying.
- TypeScript: run `tsc -b` (build mode, not just `tsc --noEmit`) before every commit — `tsc -b` uses tsconfig.app.json which includes stories and test files and is stricter. If the project has a `npm run validate` script, prefer that (it combines `tsc -b`, format check, and tests). A build that only compiles Storybook is not sufficient.

## Git workflow

- Default to ONE clean commit per request unless told otherwise; when addressing review feedback, amend/squash into that commit rather than adding fixup commits.
- Before auditing or editing, confirm the current branch and repo with `git branch --show-current` and `git remote -v`. If the user names a branch, use it.
- For multi-fix requests, use one branch with a separate commit per fix when asked.

## Testing & Verification

### Verification

- After code changes, run lint, typecheck, and tests before declaring done. If something cannot be run (Node version mismatch, sandbox blocks crates.io, no browser), say so explicitly at the end under 'Not verified'.
- Check `.nvmrc`/`nvm use` before running JS tooling; Node version mismatches have blocked lint/build repeatedly.
- For UI changes, state which Storybook story or page should be checked manually.
- After pushing, check CI status with `gh pr checks` instead of assuming it passed.

## Environment

### Environment notes

- macOS: BSD sed is in use; use python3 or `sed -i ''` for in-place edits.
- MCP servers are registered via `claude mcp add` (stored in ~/.claude.json), not settings.json.
- Disk can fill up; check `df -h` if writes fail.
- Use `gh api` for fetching Dependabot alerts.
