---
created_at: 2026-09-03T13:39:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Name a declaration nobody can re-probe as unmeasured

## Overview

«A declaration nobody has re-probed is refused, the same way a discharge nobody recorded
is refused.» This ticket makes the prose-only declaration visible as its own class — not false,
not true, unmeasured — at the writing seam and in the audit, without retro-blocking anything
already on disk.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` — the write-time ticket floor on the `todo/` queue
- `plugins/workaholic/hooks/validate-mission.sh` — the mission floor
- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the writing rule
- `plugins/workaholic/hooks/layout-doctor.sh` — the read-only audit that reports without failing a merge
- `plugins/workaholic/skills/specificate/scripts/scaffold-proposed-ticket.sh` — the unattended writer

## Implementation Steps

1. At the **writing** seam only: a ticket newly written into `todo/` that declares
   `verification_handoff:` and no `verification_probe:` is reported by `validate-ticket.sh` with
   the repair named. Decide and record whether that is a refusal or a warning — a refusal is
   defensible at a write seam the loop controls, and the deciding fact is whether every handoff
   this repository's writers emit can honestly carry a probe.
2. **Nothing already on disk is retro-blocked.** The archive is history and a queued ticket
   written before this existed is not a defect its author can fix; grandfathering is the same
   rule `validate-feedback.sh` and `validate-story.sh` already hold.
3. Report the standing set in `layout-doctor.sh` as an **advisory**, never a finding: each queued
   or active declaration carrying no probe, named with its path. An advisory does not fail the
   merge gate, which is right for a condition that harms nothing until a unit is claimed.
4. State the rule in `ticket-format.md` beside the existing handoff-writing rule, in the same
   voice: a handoff names a probe, and one that cannot is declaring that no command can decide
   it — which is a thing to say out loud, not a default.
5. Make `scaffold-proposed-ticket.sh` report `handoff_without_probe` when it writes one, so
   `/specificate`'s run report and pull-request body name it rather than leaving it silent.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A newly written queued ticket declaring a handoff with no probe is reported at the write seam with the repair named.
- No ticket already tracked in git is blocked or rewritten by this change.
- `layout-doctor.sh` lists each standing prose-only declaration as an advisory and `conforming` stays true.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — rows over a new declaration, a grandfathered one, and the advisory.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` against this repository, output recorded in the branch story.

**Gate** — what must pass before approval:

- The audit reports and never writes; `conforming: false` is not reachable from this class.

## Considerations

- The refusal-versus-warning fork in step 1 is decided by the measurement ticket 1 takes. It is
  recorded here as the deciding fact rather than pre-empted, and it is a judgement a driving run
  can make from that evidence — not an operator-only ruling.

## Final Report

**Outcome**: implemented.

`unmeasured` is now its own class — **not false, not true** — reported by the one reader per member
and once for the unit, and named at both surfaces the ticket asked for: the writing seam
(`create-ticket/reference/ticket-format.md`) and `/moderate`'s `handoff-units` question, which now
says that this declaration was **not checked** rather than letting an operator assume it was.

**It gates nothing, and that is the whole of "without retro-blocking anything already on disk".**
All six declarations in the tree are prose, so all six are `unmeasured`; making the class a refusal
would park the work they name with no way to unpark it. What the class buys is visibility.

**It is distinguishable from an absent declaration**, which is neither `measurable` nor
`unmeasured` — *nobody said anything* and *somebody said something nobody can re-check* are
different facts, and collapsing them would lose exactly the one the ticket exists to surface.

**Verified**: `node scripts/test-workflow-scripts.mjs` asserts all three classes, including that an
absent declaration carries neither flag.
