## Communication

- Technical, direct, compact. No preamble, no recap, no over-explaining.
- Go deeper only if I ask, or say I'm new to / learning a topic.
- Recommend one option with a short reason; don't survey alternatives unless asked.

## Tool Names

- Tool names are case-sensitive and capitalized: `Bash`, `Read`, `Edit`, `Write`, `Grep`, `Glob`. Never call `bash`, `read`, etc.; a wrong-case call errors and wastes tokens.

## Engineering Principles

- Existing projects: follow their stack, conventions, and tooling. Don't retrofit anything from "Defaults for New Projects" (Docker, Makefile, i18n, Tailwind, linters, version pins) unprompted; suggest it in one line instead.
- Do what was asked. Minimal diffs; match surrounding style, naming, and comment density. Mention adjacent issues, don't fix them.
- Accessibility matters: semantic HTML, labels, keyboard navigation, focus states, contrast, ARIA only when needed.
- Dark mode supported, but the user chooses: light / dark / system (default system, persist the choice).
- Report outcomes to users with toast messages (success and error); no silent failures.

## Defaults for New Projects

Use the current stable release of every dependency: check the registry (`npm view <pkg> version`, `cargo search`, `pip index versions`), not memory. Don't copy outdated versions or deprecated APIs from old docs.

- **Frontend:** React + TypeScript + Vite, TanStack Query, react-router, a toast library (e.g. sonner), react-i18next (no hardcoded UI strings; never add i18n to an existing project that lacks it). Tailwind for AI-generated UI.
- **React state:** `useReducer` over multiple related `useState`s; server state in react-query, not local state/effects.
- **Runtime:** Docker + docker compose; one `docker compose up` should work.
- **Editors:** VS Code or Neovim; commit only shared settings, no personal editor files.
- **Scripts:** Rust > Python 3 > Bash by complexity. Bash only for thin glue; switch once there's logic, parsing, or error handling.

## Project Hygiene

- **Quick start:** `Makefile` or `package.json` scripts for install, dev, build, test, lint, format, validate.
- **README:** "Getting started" section at the top: prerequisites, setup, run, test, fewest commands possible.
- **Pin versions:** `.nvmrc`, `.python-version`, `rust-toolchain.toml`, Dockerfile base-image tags, committed lockfiles.
- **Tooling:**

  | | Format | Lint | Dead code / types |
  |---|---|---|---|
  | JS/TS | prettier | eslint | knip, `tsc -b` |
  | Python | black | ruff | ruff, mypy |
  | Rust | rustfmt | clippy | compiler `dead_code` warnings, `cargo check` |

- Wire these into the quick-start tasks and CI, not just editor hooks.

## Git

- NEVER run `git checkout --`, `git restore`, `git stash`, or `git reset --hard` on files with uncommitted changes. Assume uncommitted work is intentional dev hacks I want to keep. Ask first.
- Before auditing or editing, confirm the branch and repo (`git branch --show-current`, `git remote -v`). If I name a branch, use it.
- One logical change per commit; default to ONE clean commit per request. Multiple fixes: one branch, one commit per fix, when asked.
- Review feedback: amend/squash into the original commit, no fixup commits.
- Before committing, diff the staged changes and strip local-only debug artifacts (e.g. `tags: ['asd']`, console.log, temporary flags).

## Verification

- Don't assert how a system behaves (enums, Redis topology, API refresh semantics, cache invalidation) without reading the code or running a command that proves it. If unverified, say "I need to check" and check.
- Never hand-compute timestamps, dates, or durations. macOS: `date -r <ts>` / `date -u` (`date -d` is GNU-only).
- Verify any log-grep or service-connecting script's pattern and port against real output before presenting it as working.
- Before declaring done, run the project's own checks (`make validate` / `npm run validate` if present, else format, lint, typecheck, tests). Anything not run (version mismatch, sandbox blocks crates.io, no browser) goes under "Not verified" at the end.
- Rust: `cargo fmt`, `cargo clippy`, `cargo check` from the crate root. Stale results: `touch` the file or `cargo clean -p <crate>`.
- TypeScript: `tsc -b` before every commit (build mode includes stories/tests and is stricter than `--noEmit`). A Storybook-only build is not sufficient.
- UI changes: state which Storybook story or page to check manually.

## Bug Hunting

When I'm investigating a bug:

1. Before writing code, list the top 3 hypotheses.
2. For each, give the exact command or file+line that confirms or rules it out.
3. Run those checks and show the raw output.
4. Propose a fix only after one hypothesis is confirmed by evidence.
5. If the evidence says no fix is needed, say so explicitly.

## Side-Notes During Active Work

Unrelated feature ideas, bug reports, or errors I mention mid-task are notes for later, not redirections.

- Acknowledge in one sentence max.
- Persist immediately in memory (`project` for bugs/errors, `feedback` for feature ideas).
- Don't investigate or implement unless I explicitly switch tasks ("actually let's do this first", "pause and fix this").
- Resume the current task without further commentary.

## Tool Versions Before Installing

Before any package install (`npm install`, `pip install`, `uv sync`, `bundle install`, etc.), verify the active runtime matches the project's declared version. Wrong versions silently corrupt lock files.

First file found wins:

| Ecosystem | Files (in order) | Verify with |
|-----------|------------------|-------------|
| Node.js | `.nvmrc`, `.node-version`, `package.json#engines.node`, Dockerfile `FROM node:X` | `node --version` |
| Python | `.python-version`, `pyproject.toml#requires-python`, `.tool-versions`, Dockerfile `FROM python:X` | `python --version` |
| Ruby | `.ruby-version`, `.tool-versions`, `Gemfile` `ruby 'X'` | `ruby --version` |
| Rust | `rust-toolchain.toml` `channel`, `rust-toolchain` | `rustc --version` |
| Java/JVM | `.java-version`, `.tool-versions` | `java --version` |

- On mismatch, switch (`nvm use`, `pyenv shell X`) before installing, including before any JS tooling run.
- Never install with a different major version than declared.
- Dockerfile `FROM` is authoritative when generating lockfiles outside the container.
- No version file: state the mismatch risk and suggest adding one.
- Version manager or required version unavailable: stop and ask.
- Install blocked by security policy/sandbox: don't work around it; give me the exact command to run myself (`! <command>`).

## Environment (macOS)

- BSD sed: use python3 or `sed -i ''` for in-place edits.
- MCP servers are registered with `claude mcp add` (stored in ~/.claude.json), not settings.json.
- Disk can fill up; check `df -h` if writes fail.
- Dependabot alerts: use `gh api`.

## Private

@sensitive-work.md
