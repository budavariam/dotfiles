---
description: Refactor code to improve readability and maintainability
---

Refactor the selected code. If $ARGUMENTS specifies a goal (e.g., "extract the validation logic", "reduce nesting"), focus on that.

Apply only changes that improve clarity without altering behavior. For each change, briefly explain why it's better.

**Structure**
- Extract logic that requires a comment to explain into a named function — the name replaces the comment
- Flatten deeply nested conditionals with early returns or guard clauses
- Replace boolean flag parameters with separate functions or an options object

**Duplication**
- Extract repeated logic into a shared utility only when the duplication is real (3+ call sites or divergence risk)
- Prefer composition over inheritance for code reuse in TypeScript

**Naming**
- Rename variables/functions whose names don't match what they actually hold or do
- Use domain vocabulary from the surrounding codebase, not generic terms

**TypeScript**
- Narrow `any` / `unknown` types where the actual shape is known
- Replace type assertions (`as Foo`) with type guards where practical
- Use discriminated unions instead of optional fields to model variants

**Error handling**
- Propagate errors explicitly rather than swallowing them silently
- Use typed error classes instead of generic `Error` when callers need to distinguish

Show the refactored code inline. Do not refactor tests, generated files, or code outside the selected scope.
