---
created_at: 2026-08-31T11:35:59+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# Drill the blocked-tick reading offline

## Overview

The reading this mission adds fires only when a tick dies — the rarest path there is, and
the one nobody will exercise by hand. Prove it offline, with a breaker written against the
behaviour rather than the return shape.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher's `case` arms, which `verify-all` derives
  its set from.
- `docs/loop-drill-runbook.md` §9 — the drill register; an unclassified drill is
  `skipped:unclassified` and the suite fails on it.


## Implementation Steps

1. Add `verify-blocked-tick` over a throwaway repository: run a tick, kill it after the
   opening persist, and prove the base carries the opening.
2. Prove the next tick names it exactly once across two ticks, that a complete previous
   section produces no question and no event, and that an unreadable log is `degraded` by
   name and asks nobody.
3. Add a **breaker** row written against the **behaviour**: remove the early persist and
   the row must fire, because the base then carries nothing to notice.
4. Keep it hermetic — no network, no `gh`, no Slack post — so it joins the set
   `.github/workflows/loop-drills.yml` runs on every push.
5. Register it in §9 in the same commit, with its classification.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-blocked-tick` passes, makes no network call and
  needs no credential.
- Its breaker row is proved able to fail on the real script's source.
- The register classifies it and `verify-all` includes it; it is not `unproved`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-blocked-tick`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Registered in §9 in the same commit as the drill itself.


## Considerations

- Killing a tick mid-run inside a drill needs a deterministic stopping point; use the
  step boundary the early persist already creates rather than a timeout, or the drill
  passes or fails by how fast the machine is.

