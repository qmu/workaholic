---
type: Story
title: Name the session type that cannot merge
branch: work-20260823-171036
created_at: 2026-08-23T17:45:00+09:00
author: tamura.yoshiya@gmail.com
assignees: [tamura.yoshiya@gmail.com]
mission: name-the-session-type-that-cannot-merge
tickets:
  - 20260821150710-name-the-session-type-merge-refusal.md
  - 20260821150710-rule-on-the-connector-as-a-merge-transport.md
feedback: [20260821150642-auto-merge-cannot-merge-in-a-web-session-while-the-connector-can.md]
---

# Name the session type that cannot merge

## Summary

A Claude Code Web session's REST merge is answered `403 "Merging pull requests is not
permitted for this session type"`, which the merge ladder collapsed into `merge_failed` —
so every proposal opened from a remote session stayed open with a report that blamed
nothing in particular. Two changes, one per ticket:

1. **The refusal has its own name.** The 405/409/`*` ladder moved out of
   `publish-tree-pr.sh` into `branching/scripts/merge-reason.sh` — a pure function over the
   response text — and gained two rungs: `session_type_cannot_merge` (keyed on GitHub's own
   sentence, because 403 alone is also a missing permission) and `merge_forbidden` (the
   generic 403 behind it, so an upstream rewording degrades to "still not a fault in the
   change" rather than to `merge_failed`). All five rungs now run for real in the hermetic
   suite; inline, they could only be asserted by reading the source.

2. **The ruling: a connector may merge, behind REST, narrowly.** `rules/shell.md`'s REST-only
   rule gains its one qualification — a merge refused `session_type_cannot_merge` may be
   retried once through `mcp__github__merge_pull_request`, agent-level, reporting both
   outcomes by name. Reads, writes and PR creation stay REST. The alternative (keep the rule
   absolute, let such proposals stay open) is recorded and lost because the honest reason had
   nobody to reach: the unit was finished, green, and waiting on a human who was never told.

## Verification

- The tick of 2026-08-23 07:33 UTC (`cse_01MTFyJuBmo1GpmnJozsYHZi`) measured the 403 live on
  a `merge_policy: review` unit; the connector's read tools worked in the same container.
- `node scripts/test-workflow-scripts.mjs`: 3426 passed, 0 failed (log tally).
- `build.mjs` + `verify.mjs` clean; the bundle carries `merge-reason.sh` into all six
  closures that ship `publish-tree-pr.sh`.

## Concerns

- (low) A connector merge is measured only in an interactive session; no tick has been
  observed merging yet. The seam reports tool-absent / refused / merged by name, so the first
  tick that exercises it will say which happened.
