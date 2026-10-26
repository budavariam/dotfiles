---
description: Run the project's own checks and report the real output
---

Run the project's validation and report results from real output only. If $ARGUMENTS names a scope or command, use it.

1. Verify the runtime matches the project's declared version before running any JS/Python/Ruby/Rust tooling (`.nvmrc`, `.python-version`, `rust-toolchain.toml`, `engines`, Dockerfile `FROM`). On mismatch, switch (`nvm use`, `pyenv shell`) first; if the version manager or version is unavailable, stop and ask.
2. Find the check entry point, first match wins: `make validate` / `npm run validate`, then the individual `format`, `lint`, `typecheck`, `test` scripts in `Makefile` or `package.json`, then the CI config (e.g. `.github/workflows`, or whichever pipeline file the repo has) to see what CI runs.
3. Fallbacks by ecosystem if there are no scripts:
   - TypeScript: `prettier --check`, `eslint`, `tsc -b` (build mode, not `--noEmit`), tests
   - Python: `black --check`, `ruff`, `mypy`, tests
   - Rust: `cargo fmt --check`, `cargo clippy`, `cargo check`, `cargo test` from the crate root (`touch` the file if results look stale)
4. Run the checks. Do not fix anything unless asked; just report.
5. Output: for each check, pass/fail with the tail of the real output (last ~15 lines for failures). Never claim a pass you did not see.
6. End with a **Not verified** list: anything skipped or blocked (version mismatch, sandbox blocks network, no browser, no tests for the touched code). For UI changes, name the page or component to check manually.
