---
description: Minimize git diff by reverting unnecessary changes
---

Run `git diff` and `git diff --staged` to see all current changes, then actually revert the unnecessary ones.

For each changed file, categorize changes as:
- **Intentional** — logic changes, new features, bug fixes: keep
- **Incidental** — formatting, whitespace, comment style that drifted from the original: revert
- **Accidental** — changes to files unrelated to the current task: revert

Specifically revert:
1. Whitespace-only line changes (trailing spaces, blank line counts) unless the project enforces them via a linter
2. Quote style changes (single ↔ double) if not enforced by the linter config
3. Import reordering that isn't driven by a formatter rule
4. Comment reformatting that changes meaning or style without adding value
5. Changes in files that should not be modified for this task

After reverting, report what was kept and why. If there are large changes that mix multiple concerns, suggest how to split them into separate commits — but don't split them without confirmation.
