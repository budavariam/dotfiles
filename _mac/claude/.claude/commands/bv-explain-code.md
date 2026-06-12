---
description: Explain the selected code in simple terms
---

Explain the selected code clearly. If $ARGUMENTS contains a specific question (e.g., "why does this use a WeakMap?"), answer that directly first, then provide the broader context.

Structure the explanation as:

1. **Purpose** — what problem this code solves, one or two sentences
2. **Mechanism** — how it works step by step, in the order the code executes
3. **Key concepts** — patterns, algorithms, or APIs a reader needs to know to understand it (link to relevant docs only if non-obvious)
4. **Gotchas** — edge cases, ordering dependencies, mutation, async traps, or anything that would surprise a reader
5. **Callers / context** — what calls this and why (read surrounding code if needed)
6. **Improvement opportunities** — only if there are clear issues; skip if the code is fine

Calibrate depth to the complexity of the code. A three-line utility needs one paragraph; a complex state machine needs each step broken down.

Do not explain what individual variable names mean if they're self-documenting. Focus on the non-obvious.
