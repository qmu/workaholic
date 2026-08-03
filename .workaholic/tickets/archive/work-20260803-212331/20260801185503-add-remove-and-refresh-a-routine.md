---
created_at: 2026-08-01T18:55:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort:
commit_hash:
category: Added
depends_on: [20260801185502-list-a-repositorys-routines.md]
mission: make-scheduled-routines-a-configurable-inspectable-part-of-a-repository
merge_policy: auto
---

# Add, remove and refresh a routine within the decided boundary

## Overview

The write half. A routine can be added, removed, or refreshed from its template — strictly
within the boundary the decision ticket set, which is the point of doing this last.

Two constraints are already known and must survive. `workaholify` confirms each create or
refresh **verbatim, one at a time**, because a routine is a standing outward-facing
process. And the routines API has **no delete**, which is why `unknown` entries are
treated as deliberate one-offs rather than deletion proposals — "remove" therefore means
something specific that this ticket must define rather than assume.

## Policies

- `workaholic:operation` / `policies/deployment-pipeline.md` — a routine is part of how the project runs; changing one is an operational act with a blast radius beyond this repository.
- `workaholic:safety` — creating a standing scheduled process is outward-facing and irreversible in practice; the confirmation bar is a safety property, not a UX preference.
- `workaholic:implementation` / `policies/command-scripts.md` — each mutation is a script with a JSON contract.

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` - the verbatim-one-at-a-time confirmation rule, and the no-delete API fact
- `plugins/workaholic/skills/workaholify/routines/` - the templates a refresh pulls from
- `plugins/workaholic/skills/workaholify/scripts/compare-routines.sh` - per-field drift, which is what a refresh resolves
- `docs/drive-loop-runbook.md`, `docs/proposal-loop-runbook.md` - the prohibition the decision ticket reconciled

## Implementation Steps

1. Implement only what the decision ticket permits. If it ruled that mutation always
   requires confirmation, that is the design — not a limitation to work around.
2. Keep the confirmation **verbatim and one at a time**: the developer sees the exact body
   that will be created, per routine. A batch confirmation is not this rule.
3. Define "remove" against an API with no delete. Disabling, re-pointing, or reporting
   that it must be done by hand are all honest answers; silently doing nothing is not.
4. Make refresh idempotent and driven by per-field drift: refreshing an undrifted routine
   changes nothing and says so.
5. Reconcile both runbooks' prohibition with what now exists, in the same change.

## Quality Gate

**Acceptance criteria**

- A routine can be added, removed and refreshed within the decided boundary, and the boundary is enforced in code rather than described in prose.
- Every create or refresh is confirmed verbatim, one at a time.
- "Remove" has a defined, honest meaning against an API with no delete, and it never silently does nothing.
- Refreshing an undrifted routine is a no-op that reports itself as one.
- Both runbooks describe the capability as it now exists.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with hermetic cases over a stubbed API for: add, refresh-when-drifted, refresh-when-clean (no-op), and the remove semantics.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` if any built skill changed.

**Gate**

- The confirmation bar is enforced in code. A standing outward-facing process created without the developer seeing its exact body is the one outcome this ticket must not allow, and prose does not prevent it.

Decided: last in the set, after listing — the boundary it must respect is set by the decision ticket, and the read half delivers the mission's stated Experience without it (developer may override at /drive).

## Considerations

- These mutations reach outside the repository, so hermetic tests must stub the API. A test that creates a real routine would leave a standing process behind on a real account.
