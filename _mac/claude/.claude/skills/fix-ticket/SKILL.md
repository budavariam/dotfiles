# Fix Ticket — Wrike-to-Worktree Bug Fix Skill

Use this skill when the user provides one or more Wrike ticket URLs and asks you to fix the issue described in the ticket. The skill fetches the ticket, creates an isolated git worktree (or works in the current checkout), implements the fix, and commits it — without modifying the ticket itself.

**Trigger phrases:** "fix this ticket", "can you fix", "fix the issue in", "work on this ticket", followed by one or more Wrike URLs.

---

## Parameters (extracted from the user's message)

| Parameter | Default | How user specifies it |
|-----------|---------|----------------------|
| **Ticket URL(s)** | — (required) | The Wrike permalink URL(s) in the message |
| **Base branch** | repo's default branch (origin/HEAD) | "from `main`", "branch off `feat/xyz`" |
| **Worktree name** | derived from ticket title (see naming convention below) | "call it `fix/1234567890_my-name`", "name it `my-fix`" |
| **Isolation mode** | worktree | "no worktree", "in the current folder", "skip the worktree" → work in the current git checkout instead |

### Branch naming convention

Always use `<type>/<id>_<kebab-case-slug>` when a ticket ID is available, or `<type>/<kebab-case-slug>` when there is no ID:

```
fix/1771681161_date-boundary-fix
fix/4433394950_multi-tenant-architecture
feat/1775473907_collection-notify
chore/update-dependencies
```

**Rules:**
- Use `/` between the type and the rest — this is the standard git branch namespace separator.
- Use `_` between the ID and the slug.
- The type comes from the nature of the work: `fix` for bugs, `feat` for features, `chore` for maintenance.
- The ID is the numeric task ID from the Wrike permalink URL (`https://www.wrike.com/open.htm?id=1771681161` → `1771681161`). Include it whenever a ticket was fetched — omit it only when working without a ticket.
- The slug is lowercase, words separated by `-`, a short description derived from the ticket title (3–5 words max).

If the user says **"no worktree"** or **"in the current folder"**: skip `EnterWorktree` and work directly in the current git checkout. Create and switch to a new branch with `git checkout -b <branch-name>`.

---

## Rules (non-negotiable)

- **Never modify the ticket** — no status changes, no comments, no field updates.
- **Never push** to the remote repository.
- If the user gives multiple tickets, **fan out agents in parallel** — one per ticket.

---

## Workflow

### Step 1 — Fetch the ticket (read-only)

```bash
wrike tasks get --permalink "https://www.wrike.com/open.htm?id=<ID>" --json
```

Read the full JSON output: title, description, acceptance criteria, technical notes. Understand the bug before touching any code.

### Step 2 — Set up the working environment

**Worktree mode (default):**

Use the `EnterWorktree` tool. Since `EnterWorktree` doesn't allow `/` in names, use `_` as the separator for the worktree folder name (e.g. `fix_1771681161_date-boundary-fix`). The base branch defaults to `origin/<default-branch>` unless overridden. `EnterWorktree` runs any `PostToolUse` setup hooks automatically.

After the worktree is created, rename the branch to the correct format (`<type>/<id>_<slug>`) — this drops the `worktree-` prefix and replaces the first `_` with `/` — then unset the upstream tracking:

```bash
git branch -m fix/1771681161_date-boundary-fix
git branch --unset-upstream
```

**Current-folder mode (`--no-worktree`):**

```bash
git checkout -b fix/<id>_<slug>   # or the user's specified branch name
```

Install deps manually if needed (`npm install`, etc.).

> **Worktrees are preferred** — they keep the main checkout clean. Only skip them when the user explicitly asks.

> If the repo has a setup script, the `EnterWorktree` hook runs it automatically. If not, install deps manually (`npm install` or equivalent) before proceeding.

### Step 3 — Explore the codebase

Locate the relevant code using `grep`, `find`, and `Read`. Do not make assumptions about file locations — search for the actual symbols, component names, or patterns described in the ticket. Read the code you plan to change before touching it.

### Step 4 — Fix the bug

Apply the minimal change that satisfies the acceptance criteria. Do not refactor, add features, or clean up unrelated code. Follow the existing patterns in the file.

### Step 5 — Run tests

Check `package.json` (or equivalent) for the test script and run it. If there is no test script, note that explicitly. If tests exist, confirm they pass before committing.

```bash
# Examples — discover the real command first
npm test -- --run          # Vitest / Jest (no watch)
npm run test:unit          # project-specific variant
```

### Step 6 — Commit

```bash
git add <changed files>
git commit -m "short, imperative description of the fix"
```

- Keep the message short and direct (e.g. `fix dropdown not closing on outside click`, `show collection modal in expanded card view`).
- No body, no ticket references required.
- **Do not push.**

---

## Multiple tickets

When the user provides more than one ticket URL, use the `Agent` tool to spawn one subagent per ticket in a single parallel call. Each subagent follows this same workflow independently. Brief each agent with:

- The specific ticket URL to handle
- The repo path to work from
- All the rules above (no ticket modifications, no push, simple commit message)

Report back to the user with a summary of what each agent did once all agents complete.

---

## Discovering the repo

If the current working directory is not inside a git repository, ask the user which repo to use before proceeding. The worktree is created inside `.claude/worktrees/` under that repo's root.

---

## Commit message style

| Bad | Good |
|-----|------|
| `fix bug in datepicker component per AC1-AC3` | `fix dropdown not closing on outside click` |
| `WIP: addressing Wrike ticket issue` | `show collection modal in expanded card view` |
| `updated constants.ts to use Temporal.Now` | `fix missing close button on settings panel` |

Short, imperative, lowercase, no trailing period.

---

## Example walkthrough

**User message:**
> Fix this ticket please: https://www.wrike.com/open.htm?id=9999999999

**Step 1 — Fetch the ticket:**
```bash
wrike tasks get --permalink "https://www.wrike.com/open.htm?id=9999999999" --json
```
Output (excerpt):
```json
{
  "title": "Modal closes immediately after opening on mobile",
  "description": "<b>Summary</b><br/>The settings modal dismisses itself on first tap on iOS...",
  "customFields": { "Priority": "P2" }
}
```

**Step 2 — Create the worktree:**

`EnterWorktree` called with `name: "fix_9999999999_modal-closes-on-mobile"`. The tool creates `.claude/worktrees/fix_9999999999_modal-closes-on-mobile` branched from `origin/main` and the setup hook runs automatically. Then rename the branch and unset upstream:

```bash
git branch -m fix/9999999999_modal-closes-on-mobile
git branch --unset-upstream
```

**Step 3 — Explore:**
```bash
grep -r "onOpenChange\|useModal\|ModalRoot" src/ --include="*.tsx" -l
# → src/components/Modal/Modal.tsx, src/hooks/useModal.ts
```
Read both files. Find that `useModal` calls `onClose` on every `touchstart` event — including the initial tap that opens the modal.

**Step 4 — Fix:**

In `src/hooks/useModal.ts`, add a guard so the `touchstart` listener is only attached after the open animation completes (i.e. after a `transitionend` event or a short delay).

**Step 5 — Test:**
```bash
npm test -- --run
# 142 tests passed
```

**Step 6 — Commit:**
```bash
git add src/hooks/useModal.ts
git commit -m "fix modal dismissing on the same tap that opens it"
```

Done. Report to user: branch `fix/9999999999_modal-closes-on-mobile` (worktree at `.claude/worktrees/fix_9999999999_modal-closes-on-mobile`) is ready with one commit. No push.
