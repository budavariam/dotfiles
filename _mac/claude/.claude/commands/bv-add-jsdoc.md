---
description: Add comprehensive JSDoc/TSDoc documentation
---

Add JSDoc/TSDoc comments to the selected code. If $ARGUMENTS specifies a focus (e.g., "public API only"), apply it.

First, scan nearby files for existing doc style — match it exactly (JSDoc vs TSDoc, spacing, tag order).

For each exported function, class, method, and non-trivial type:

1. One-line summary (imperative mood: "Returns the...", "Transforms...")
2. `@param` — include type only if not already in the TypeScript signature; always include a description
3. `@returns` — describe what the value means, not just its type
4. `@throws` — document every thrown error type and the condition that triggers it
5. `@example` — include at least one realistic usage example for public API surface
6. `@remarks` — for non-obvious constraints, invariants, or side effects
7. `@see` / `{@link}` — link to related functions, types, or external docs
8. `@deprecated` — only if actually deprecated; include the migration path

Skip trivial getters/setters, private helpers, and types whose name already fully describes them.

Do not add a comment that merely restates the function signature.
