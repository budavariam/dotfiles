---
description: Update README and docs to match the changed behavior
---

Update documentation to match what the current changes do. $ARGUMENTS may name specific docs or a scope.

1. Run `git diff` and `git diff --staged` (and `git diff <base>...HEAD --stat` on a feature branch) to see what behavior, commands, flags, config, or setup changed.
2. Find the docs that describe those things: `README.md`, `docs/`, e2e/UI spec folders, `CLAUDE.md`, `.env.example`, script help text. Update only docs that are now wrong or missing something; leave the rest untouched.
3. README rules: keep a "Getting started" section at the top with prerequisites, setup, run, test, using the fewest commands possible. Check every command you write exists in `Makefile` or `package.json` scripts.
4. Match the existing docs' tone, heading style and length. Minimal diffs; do not reflow or restyle unrelated paragraphs.
5. Do not add JSDoc/TSDoc or code comments unless I ask; this command is for prose docs only. Do not document planned or unfinished work as if it ships.
6. Report which docs you changed and what you deliberately left alone. List anything you could not verify (a command you did not run, a URL you did not open).
