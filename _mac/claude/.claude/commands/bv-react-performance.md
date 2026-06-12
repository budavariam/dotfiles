---
description: Optimize React component code for performance
---

Analyze the selected React code for performance issues and apply fixes where the gain is clear. If $ARGUMENTS specifies a concern (e.g., "re-renders", "bundle size"), prioritize it.

First check the React version in package.json — available optimizations differ significantly.

**Re-renders**
- Identify components that re-render when their props haven't changed; add `React.memo` only if the component is expensive
- Replace inline object/array/function literals in JSX with stable references (`useMemo`, `useCallback`) — but only where profiling or obvious logic confirms it's needed
- Colocate state close to where it's used to avoid unnecessary parent re-renders

**React 18+ specific**
- Wrap non-urgent state updates with `startTransition` / `useTransition` to keep the UI responsive
- Use `useDeferredValue` for expensive derived values tied to user input
- Use `Suspense` boundaries to progressively load heavy subtrees

**React 19 / React Compiler**
- If the React Compiler is enabled, `useMemo`/`useCallback` are often unnecessary — note which ones can be removed

**Expensive computations**
- Move pure calculations out of render into `useMemo` with correct dependencies
- Virtualize long lists (react-window, react-virtual) instead of rendering all items

**Code splitting**
- Lazy-load routes and heavy components with `React.lazy` + `Suspense`
- Check that large third-party libraries aren't imported in the critical path

For each suggestion, explain the specific re-render or computation it prevents. Do not add memoization speculatively — only where there is a concrete benefit.
