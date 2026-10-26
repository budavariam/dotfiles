---
description: Summarize the branch changes as a PR description, checklist, or executive summary
---

Summarize what this branch changes. $ARGUMENTS selects the format: `checklist` (default), `pr` (full PR body), or `exec` (executive summary); it may also name a base branch or several repos.

1. Confirm repo and branch (`git branch --show-current`), then find the base (default branch or the one given). Read `git log --oneline <base>..HEAD` and `git diff <base>...HEAD --stat`, then the diff itself where the stat is not enough. Work from the diff, not from memory of the conversation.
2. Formats:
   - `checklist`: `* [x] short description` per item, simple sentences, one line each, no per-item detail.
   - `pr`: a short "What / Why" paragraph, then the checklist, then "How to test" with concrete steps or the page/component to open. Add "Not verified" only if something wasn't run.
   - `exec`: 3-6 sentences for a non-technical reader: what was done, what users get, risks. For multi-repo work, one short paragraph per repo.
3. Group related changes into one item; skip formatting-only and incidental changes. Don't mention files that were reverted.
4. Mention a ticket link only if it appears in the branch name, commits, or what I pasted; never invent one.
5. No LLM attribution, no emojis. Output the text only, ready to paste.
