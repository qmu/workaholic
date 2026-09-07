---
created_at: 2026-09-06T08:20:31+09:00
status: done
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

## Final Report

**Reproduced first (step 1).** Fed `claimable-units.sh` a survey whose only work was one
`report_undelivered` unit: it answered `{"claimable":0,"missions":0,"backlog_units":0,"resumable":0}`
— **byte-identical** to the answer for a repository with genuinely nothing to do. The exclusion is
visible at the header's own words (*`parked_with_pr`, `awaiting_verification` and `superseded` are
not*, which never named the recovery verdicts at all) and at the `jq` sum, which added only
`missions + backlog_units + resumable`.

**Implemented.** The count now composes readers that already exist — `plan-units.sh`'s own
`undelivered[]`, `drive/scripts/list-catchable-claims.sh`, and
`branching/scripts/list-stranded-publications.sh` (only the `mechanical` / `clean` / `content`
classes the settle act operates on). No second walker, no new field on any artifact, no verdict
re-derived.

**The one judgement made here, and its reason: all recovery work is ONE unit.** Those three acts
are once-per-run readings inside the Unified Run, so a single `/implement` pass walks every entry;
counting per entry would spawn N runners to do one runner's work and race them on the same pull
requests. `recovery_units` is therefore 0 or 1, with `undelivered` / `catchable` / `stranded` riding
beside it so the tick's allocation line can name which term earned the runner. A unit in two sets is
counted once.

**Per verdict, whether the old exclusion still holds** (the Considerations asked for this):
`superseded` holds nothing to drive and its retirement is CI's — uncounted. `parked_with_pr` waits
on a person by the oracle's own word, and its actionable half is already reached through the
catchable term — uncounted. `awaiting_verification` waits on a declared verification, and this
reader runs no probes; counting it on the chance a probe now reads `clean` would spawn a runner on
a guess — uncounted.

**Cost, decided and stated** (the Considerations asked which): the survey is still paid for once
(`--survey` unchanged), and the two recovery readers add bounded REST listings, once per tick rather
than once per entry. `--recovery <path|->` is the same escape hatch for a caller that has already
made those readings; the suite uses it to stay hermetic. Measured live here: 46s for the whole
reader.

**Reproduction re-run, now answering differently** — each acceptance criterion, in order:
- only an undelivered unit → `{"claimable":1,...,"recovery_units":1,"undelivered":1}`
- only a catchable claim → `claimable:1`, `catchable:1`
- only a stranded publication → `claimable:1`, `stranded:1`
- nine recovery entries across all three → `claimable:1`, `recovery_units:1` (one unit, not nine)
- one unit in both sets → `claimable:1` (counted once)
- two missions plus recovery work → `claimable:3` (it adds, never replaces)
- genuinely nothing to do → `claimable:0`, `readable` absent
- an unreadable recovery component → `{"readable":false,"reason":"recovery_unreadable","claimable":null}`
- a blind survey → still `{"readable":false,"reason":"not_current","claimable":null}`

**Gate.** `node scripts/test-workflow-scripts.mjs` — **6663 passed, 0 failed**. The suite's own
`claimable-units.sh` row was rewritten to hand both readings in (`--survey <file> --recovery <file>`)
so it stays hermetic — without that it would reach GitHub — and it now pins the recovery term, the
one-unit rule, the dedup, the addition, the still-zero case and the unreadable component.

**Docs updated in the same change**: `skills/loops/SKILL.md`, `commands/infinite-development.md`
(the §3 allocation line now names the recovery term that earned the runner) and `CLAUDE.md`'s *Loops*.
