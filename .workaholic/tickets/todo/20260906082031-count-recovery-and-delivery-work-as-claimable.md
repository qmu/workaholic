---
created_at: 2026-09-06T08:20:31+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-the-backlog-without-handing-it-back-to-the-operator
merge_policy:
verification_handoff: 
---

# Count recovery and delivery work as claimable

## Overview

`loops/scripts/claimable-units.sh` counts missions, one backlog unit and only the
`heartbeat_lapsed` / `report_incomplete` resumptions, so a repository whose only actionable
work is an undelivered unit, a catchable claim or a stranded publication reads **zero
claimable** and the tick spawns no `implement` runner at all. That is the measured failure
the ask reports: 28 tickets waiting, zero units, four conflicting pull requests, and no pass
ever ran to inspect them. Dispatch eligibility must include actionable recovery and delivery
work even when no ticket is newly claimable.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the loop is a running system; a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/loops/scripts/claimable-units.sh` — the counter; its header
  states the current rule and why `parked_with_pr` / `awaiting_verification` / `superseded`
  were excluded.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey it composes; already
  emits `undelivered[]` and `resurveyed[]`, which nothing here reads.
- `plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` — this identity's
  reported claims whose `mergeability` is `mechanical` or `content`.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — the open
  publications an `/implement` pass already settles.
- `plugins/workaholic/skills/work/SKILL.md`, `plugins/workaholic/commands/infinite-development.md`
  — where the allocation is decided and reported.
- `CLAUDE.md` — *Loops*, the allocation paragraph.

## Implementation Steps

1. **Reproduce and localize.** Seed a repository whose only work is one `report_undelivered`
   unit (and, separately, one catchable claim and one stranded publication) and run
   `claimable-units.sh`. Record that it answers `claimable: 0` while an `/implement` pass
   would have acted. Confirm the exclusion at the header's own words and at the `jq` sum.
2. Separate the two questions the header currently answers with one number: *is there a new
   unit to claim* and *is there work an `/implement` pass would act on*. Only the second
   governs whether a runner is worth spawning.
3. Widen the count by **composing readers that already exist** — `plan-units.sh`'s own
   `undelivered[]`, `list-catchable-claims.sh`, `list-stranded-publications.sh`. No second
   walker, no new field on any artifact, no re-derivation of a verdict.
4. Keep the degradation contract exactly: a reading that could not be made answers
   `readable: false` with a named reason and **null** counts, never zero — a blind survey
   must not be spent as an allocation.
5. Report the composition in the tick's §3 allocation line, so a tick that spawned a runner
   for recovery work rather than for a ticket says which.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With no newly claimable ticket and one undelivered unit present, `claimable-units.sh`
  answers a non-zero count naming the recovery term that produced it.
- An unreadable component leaves the whole answer `readable: false` with its reason and null
  counts, never a zero.
- A repository with genuinely nothing to do still answers zero.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- the reproduction named in step 1, re-run, now answering differently

**Gate** — what must pass before approval:

- the suite and the classified drill set both pass, and step 1's reproduction is shown before and after

## Considerations

- **The ask's hypothesis**, recorded as a hypothesis rather than the design: it proposes that
  dispatch eligibility include actionable recovery/delivery. Step 1 must establish the
  behaviour before step 3 acts on it.
- **Cost.** `plan-units.sh` is measured at 68–73 seconds per survey and the added readers
  reach the network. Whether the count is taken from an already-made survey (`--survey`) or
  pays again is a real decision; state which and why.
- `parked_with_pr` and `awaiting_verification` were excluded for stated reasons. Widening
  must say, per verdict, whether the reason still holds — the `verification_handoff` probe
  form (2026-09-03) already falsifies one of them at claim time.
