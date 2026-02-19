---
description: Clean up LLM-generated code to minimize diffs
---

Review the selected code or file and clean it up by:

1. Remove verbose comments that just restate what the code does
2. Remove emojis and decorative markers (e.g., "ADDED", "CHANGED", "FIXED")
3. Simplify multi-line comments to be concise and technical
4. Remove unnecessary inline comments
5. Keep only essential documentation (JSDoc, complex logic explanations)
6. Preserve copyright headers and license information

The goal is to minimize the diff compared to standard production code while maintaining clarity.
