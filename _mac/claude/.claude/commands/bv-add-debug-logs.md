---
description: Debug TypeScript/JavaScript by adding detailed logging
---

Add targeted logging to help debug the code in the current context. If $ARGUMENTS is provided, focus on that specific area or question.

First, check if the project uses a logging library (winston, pino, debug) via package.json — prefer it over raw `console` calls.

Add logging that covers:

1. Function entry with parameter values (serialized safely — avoid logging secrets or circular refs)
2. Key intermediate values and state transitions
3. Which branch was taken in conditionals with the deciding condition
4. Function exit with return value or thrown error
5. Async boundaries: when a promise is awaited and when it resolves/rejects

Naming: prefix each log with `[DEBUG:<FunctionName>]` so they're greppable.

If the project has no logger, use `console.log` with a consistent prefix rather than emojis.

After adding logs, note which lines to remove once the issue is found — logging is temporary.
