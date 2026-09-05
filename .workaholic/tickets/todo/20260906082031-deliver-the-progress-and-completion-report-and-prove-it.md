---
created_at: 2026-09-06T08:20:31+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: work-a-recoverable-state-instead-of-handing-it-over
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
verification_handoff: 
---

# Deliver the progress and completion report, and prove it

## Overview

A report written into a local transcript is not a delivered report. The current quiet-tick
policy and the exact-thread refusal leave the initiating user with neither the periodic
progress nor the final result the ask names — and a shell launcher cannot promise a callback
into the initiating chat without an actual return transport. A missing historical thread must
not erase the operator-facing account of current progress: an unresolvable lookup posts a new
keyed root, which is what the lookup's own not-found branch already exists for.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the loop is a running system; a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the tick's ceiling for what it
  posts and where.
- `plugins/workaholic/skills/notify/SKILL.md` and `reference/notifications.md` — the shapes,
  the transports, and the stateless thread lookup with its case-4 root.
- `plugins/workaholic/skills/story/scripts/record-unposted-line.sh`,
  `read-unposted-line.sh`, `clear-unposted-line.sh` — the existing carry-and-retry shape for a
  refused post; compose it rather than re-deriving it.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the relay envelope and ack paths.
- `plugins/workaholic/skills/work/reference/other-agents.md` — where the return transport per
  surface is stated.

## Implementation Steps

1. **Reproduce and localize.** Run one tick whose thread lookup resolves nothing and record
   where its report ends up. Record separately what a `codex exec` worker's report reaches and
   what the initiating chat receives.
2. Establish the supported reporting destination per entrypoint, named at startup: an absent
   delivery path is **named**, never substituted for one that delivers somewhere else.
3. Consume the worker outcomes ticket 3 made trustworthy and compose the periodic report from
   them, not from the coordinator's own guess.
4. Record delivery acknowledgement, and recover a failed delivery **without duplicate posts** —
   the unposted-line record is idempotent and clears on a landed send; use it.
5. A missing thread posts a new keyed root rather than nothing. Never a similarity match,
   never recency; the not-found branch is what makes the lookup safe.
6. State the completion report's own contract: it rests on merged work plus a fresh queue and
   pull-request reconciliation, not on the tick's own bookkeeping.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Successive tick reports and one completion report reach the selected surface, and each is
  proved delivered rather than assumed.
- A failed delivery is retried once and never duplicated; a still-refused one is reported as
  unposted.
- An unresolvable thread produces a keyed root, and a session with no delivery path says so at
  startup.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- the reproduction named in step 1, re-run, now answering differently

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- **The ask's constraint**, recorded as given: a shell launcher cannot promise a callback into
  the initiating chat without an actual return transport. Step 2 must measure what each
  entrypoint really exposes rather than assume the Claude-Code shape.
- Duplicate-post risk is the real hazard here; the existing unposted-line record is the
  reason this needs no new store, cursor or timer.
- The quiet-hours and cool-down rules exist for a reason and are not swept aside — what
  changes is that the initiating user's own run reports to them, which is not the channel
  waking somebody to say nothing.
