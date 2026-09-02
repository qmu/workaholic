---
created_at: 2026-09-02T04:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
claim: work-20260903-013925
---

# Cover every writer of the tick log, not the moderation tick alone

## Overview

PROPOSED. The measured accumulation on the base carried two commit vocabularies, not one:
`Log the moderation tick` *and* `Log the propose tick`. Both rode the same
`.workaholic/moderations/` day files. The off-main design and every guard written for it
are phrased against the moderation tick, so a guard that names that tick alone leaves the
other writer free to put the log back on the base.

This ticket proves the set of writers from the tree rather than from memory, and makes the
guard and the drill cover all of them.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — documented as the only
  writer of the log; this ticket establishes whether that is still true.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the publisher the sibling
  ticket adds the destination refusal to; the refusal must be reachable from every caller.
- `plugins/workaholic/commands/propose.md`, `plugins/workaholic/commands/moderate.md` — the
  two commands whose runs produced the two commit vocabularies.
- `scripts/e2e/loop-drill.sh` and `docs/loop-drill-runbook.md` §9 — the drill and its
  register; the drill that fails when a tick log reaches `main` must fail for any writer.
- `scripts/test-workflow-scripts.mjs` — where the writer set is pinned.

## Implementation Steps

1. Establish the writer set from the tree: find every path that appends to or commits
   `.workaholic/moderations/`, and every caller of `log-append.sh` and `persist-log.sh`.
   Write the list into the ticket's own record of what it found — the guard is only as good
   as this enumeration.
2. If a writer exists outside `log-append.sh` / `persist-log.sh`, route it through them
   rather than adding a second guard: one writer with one refusal is the property, and two
   guards drift.
3. Extend the drill so it fails when *any* of the enumerated writers puts a day file on the
   base — parameterised over the writer set, never one case per tick name.
4. Add a suite assertion that the enumerated set matches what the tree holds, so a new
   writer added later fails the build rather than silently escaping the guard.
5. Correct every prose surface that says "the moderation tick's log" where it means "the
   tick log": `workaholic:moderate`, `CLAUDE.md`, and the drill runbook, in this change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The writer set is derived from the tree and pinned, not listed by hand in prose alone.
- The drill fails for a base-bound log write from any enumerated writer.
- No prose surface still implies the guard covers the moderation tick only.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The new suite assertion fails when a synthetic extra writer is introduced.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

## Considerations

- The enumeration is the risk: a writer reached only through an interpolated path cannot be
  found by a literal search. Say so in the assertion's own name, as the suite already does
  for jq programs built by interpolation, rather than implying the set is complete.
