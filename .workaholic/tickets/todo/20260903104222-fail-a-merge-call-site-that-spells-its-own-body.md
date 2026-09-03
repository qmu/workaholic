---
created_at: 2026-09-03T10:42:22+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# Fail a merge call site that spells its own body

## Overview

`merge-method.sh` is protected by a suite row that fails on a literal `merge_method=` at a call
site — which is why the method could not drift back. The body needs the same protection, and it
needs one more assertion the method never needed: that a merge call site passes a body at all. A
call site that simply omits the fields is the exact defect this mission repairs, and omission is
invisible to a literal-text check.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `scripts/test-workflow-scripts.mjs` — the suite; the existing `merge_method=` row is the model.
- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — the reader every call site must
  name.


## Implementation Steps

1. Add a row that fails on a literal `commit_message=` or `commit_title=` value at a call site,
   mirroring the `merge_method=` row.
2. Add a second row that enumerates every `pulls/<n>/merge` call site under `plugins/` and fails
   when one does not read `merge-commit-body.sh`. The enumeration is derived from the tree, never
   a hand-kept list.
3. Cover the two agent-level ceilings by asserting the instruction text is present in each.
4. Name in the assertion what it cannot see — an agent's composed call at run time — so the row's
   own name states its bound rather than implying a stronger one.
5. Run the suite and confirm both rows fail against a deliberately reverted call site.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A call site spelling a body literal fails the suite.
- A merge call site that reads no composer fails the suite.
- Both rows are proved by reverting a call site and watching them go red.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The same run against a locally reverted call site, confirming the failure.

**Gate** — what must pass before approval:

- The call-site enumeration is derived from the tree.
- The assertion names its own bound.


## Considerations

- Enumerating merge call sites by pattern will match a comment or a documentation example. The
  row should exclude comments the way the existing `gh issue|pr|repo` row does.
