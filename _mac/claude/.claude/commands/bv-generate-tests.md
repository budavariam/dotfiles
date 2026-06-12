---
description: Generate test cases for the selected code
---

Generate tests for the selected code. If $ARGUMENTS specifies a framework or focus (e.g., "unit only", "use vitest"), apply it.

Before writing any tests:
1. Read `package.json` to identify the test framework (Jest, Vitest, Mocha, etc.) and any testing utilities (Testing Library, Supertest, etc.)
2. Find an existing test file for this module or a sibling module to match naming conventions, import style, and helper patterns exactly

Then generate:

**Unit tests**
- Happy path for each public function/method
- Boundary conditions (empty input, zero, max values, empty arrays)
- Invalid / unexpected input (null, undefined, wrong types where JS allows it)
- Each distinct error branch

**Async code**
- Resolved and rejected promise paths
- Timeout or cancellation if relevant

**Side effects**
- Verify calls to dependencies (mocks/spies), not just return values
- Test cleanup if the code registers listeners, timers, or resources

**Integration tests** — only if the selected code crosses a real system boundary (DB, HTTP, filesystem)

Place tests in the same structure as existing tests. Use `describe` blocks matching the module/class name. Each `it`/`test` description should read as a complete sentence: "returns null when the list is empty".

Do not mock things that don't need mocking — prefer real implementations for pure functions.
