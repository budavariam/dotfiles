---
description: Review code for common security vulnerabilities
---

Review the selected code for security vulnerabilities. If $ARGUMENTS specifies a focus (e.g., "auth", "input handling"), prioritize it.

Check for issues from OWASP Top 10 (2021) and common Node.js/TypeScript attack surfaces:

**Injection**
- Unsanitized user input in SQL, NoSQL, shell commands, LDAP, or eval
- Template injection in server-rendered output
- XSS: user-controlled values rendered as HTML without escaping

**Authentication & Authorization**
- Missing or bypassable auth checks on sensitive routes
- Broken object-level authorization (user A can access user B's data)
- JWT: algorithm confusion (alg: none), missing expiry validation, weak secrets

**Data Exposure**
- Secrets, API keys, or passwords hardcoded or logged
- Overly broad API responses exposing fields the caller shouldn't see
- Sensitive data in URLs (query params, path segments) that get logged

**Input Handling**
- Missing validation on external data (request body, headers, URL params)
- Path traversal via user-supplied file paths
- Prototype pollution via `Object.assign`, spread, or JSON.parse with untrusted input

**Dependencies & Configuration**
- `require('child_process')` with unsanitized input
- `eval`, `new Function`, or `vm.runInNewContext` with dynamic content
- Missing rate limiting or brute-force protection on auth endpoints
- CSRF: missing token validation on state-mutating endpoints

For each finding, rate severity (critical / high / medium / low), show the vulnerable code, and provide a corrected version.
