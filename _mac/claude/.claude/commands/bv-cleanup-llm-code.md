---
description: Clean up LLM-generated code to minimize diffs
---

Review the selected code and clean up LLM artifacts so the result looks like production code a human would write.

Remove:
1. Inline comments that restate what the code does ("// increment counter", "// return the result")
2. Section dividers and decorative markers ("// === SECTION ===", "// ADDED:", "// CHANGED:", "// FIXED:")
3. Emojis in comments or strings (unless part of intentional UI copy)
4. Redundant `as unknown as T` double-cast patterns LLMs add to satisfy TypeScript
5. Overly defensive null checks on values that cannot be null given the types
6. Unnecessary intermediate variables introduced only to add a log or comment
7. Redundant re-imports or duplicate import lines
8. Verbose `try/catch` wrappers that just rethrow without transformation

Keep:
- Copyright and license headers
- JSDoc on public API
- Comments explaining non-obvious invariants or workarounds
- Intentional defensive checks at actual system boundaries (user input, API responses)

Goal: the final diff vs. the original codebase should contain only intentional, meaningful changes.
