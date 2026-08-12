---
created_at: 2026-08-12T15:56:20+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812155518-plan-units-sh-strands-a-ticket-whose-mission-has-closed.md]
merge_policy:
claim: work-20260812-180600
---

# Stop stranding a ticket whose missions have all closed

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

A ticket carrying a `mission:` relation is dropped from the backlog offer by
`plan-units.sh` with reason `mission_member`, on the premise that it will be offered as
part of its mission's unit instead. Only missions under `.workaholic/missions/active/`
are scanned as mission units, so once every mission a ticket names has closed, the
premise stops holding: the ticket is offered by neither path and no survey — attended
`/drive` or unattended `/implement` — proposes it again. It stays in `todo/` and the
queue does not read as broken, it reads as drained.

Reported at qmu/workaholic#382 with an observed impact of six tickets unreachable for
weeks in one repository, five of them genuinely open work.

## Policies

- `workaholic:implementation` / `policies/observability.md` — an item dropped from an
  unattended run's offer must be distinguishable, in the report, from one that was never
  there; `mission_member` on a closed mission is a reason that misreports the fact.
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure
  conventions; POSIX `sh`, no bashisms (`plugins/workaholic/rules/shell.md`).
- `workaholic:implementation` / `policies/directory-structure.md` — the script stays in
  the skill that owns the survey; the mission-liveness question belongs beside the
  mission scripts.

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey. The ticket loop
  excludes on any non-empty relation (around the `read-relation.sh` call, ~L432); its
  header enumerates every exclusion reason, so a new reason is documented there too.
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the single reader of the
  `mission:` relation. Answers *which missions does this artifact name*, with no notion of
  whether any of them is alive; the liveness question likely belongs beside it rather than
  being re-derived per caller.
- `plugins/workaholic/skills/drive/reference/survey.md` — the survey contract, where the
  exclusion reasons and their meanings are documented for a reader.
- `docs/drive-loop-runbook.md` — names `mission_member` in the operator-facing account of
  the survey.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the drive-script tests build
  throwaway repositories and are where this regression gets pinned.
- `plugins/workaholic/skills/mission/scripts/close.sh` — the only writer of an end state;
  relevant only to the Open Decision below, not necessarily touched.

## Implementation Steps

1. **Reproduce first, before changing anything.** In a throwaway repository (the pattern
   `scripts/test-workflow-scripts.mjs` already uses): create a mission with two tickets,
   archive one, close the mission `achieved` so it moves to `missions/archive/`, leave the
   second ticket in `todo/`, and run `plan-units.sh`. Record the actual JSON: the expected
   observation is the surviving ticket under `excluded` with reason `mission_member` and
   absent from `backlog`. Do not proceed on the report's description alone.
2. **Localize.** Confirm the two halves of the defect independently: (a) the ticket loop
   excludes on a non-empty relation without consulting mission state, and (b) the mission
   loop enumerates `missions/active/` only, so an archived mission contributes no unit.
   State which of the two the fix changes, and confirm nothing else consumes
   `mission_member` as a signal (`grep` the reference docs and the test suite).
3. **Decide where liveness is answered** and write it once. The candidate site named by
   the reporter is next to `read-relation.sh` — a reader that answers *which of this
   artifact's missions are still active* — so that no caller re-derives "is this mission
   alive" from a directory layout. Keep the existing reader's contract untouched;
   add the liveness answer beside it rather than widening it in place.
4. **Fix the survey.** In `plan-units.sh`, count a ticket as `mission_member` only when at
   least one of its named missions is still active. A ticket whose missions have all
   closed falls through to the ordinary backlog offer. Emit a distinct, reported outcome
   for the repaired case (the reporter suggests `mission_closed`) so an operator can see
   that a repair happened rather than infer it — decide whether that reads as an
   `excluded` reason or as an annotation on the backlog row, and say which in the Final
   Report, since a *repaired* ticket is not excluded at all.
5. **Handle the many-valued relation explicitly.** `mission:` is a list; a ticket naming
   an active mission and a closed one stays a `mission_member` (it still arrives through
   the live mission's unit) and must not be double-offered.
6. **Keep the docs in the same change**: the exclusion-reason list in the `plan-units.sh`
   header, `drive/reference/survey.md`, and `docs/drive-loop-runbook.md`.
7. **Pin it.** Add a hermetic case to `scripts/test-workflow-scripts.mjs` reproducing
   step 1 and asserting the ticket now appears in `backlog`; keep a case asserting that a
   ticket of an *active* mission is still excluded `mission_member`.
8. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) — a drive script changed,
   so the bundle is stale until rebuilt, and `Outputs Freshness` CI fails on the diff.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A ticket whose every named mission is closed appears in `plan-units.sh`'s `backlog`.
- A ticket naming at least one active mission is still excluded `mission_member` and is
  offered only within that mission's unit.
- The repair is visible in the survey JSON, not inferred.
- The exclusion-reason documentation matches the emitted reasons in all three places.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new case plus the retained one, green.
- The step-1 reproduction re-run against the fixed script, before/after JSON in the Final
  Report.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

**Gate** — what must pass before approval:

- The reproduction is recorded before the fix, per the diagnosis-first rule.
- No change to `read-relation.sh`'s existing output contract (four seams read it).
- The Open Decision below is resolved explicitly in the Final Report, not silently.

## Open Decisions

Recorded verbatim from the reporter, who left them to a maintainer; `/propose` cannot ask,
so the driving session resolves them explicitly and records the resolution.

- **The close path is the other candidate site.** "Closing a mission could clear, or offer
  to clear, the stamp on each of its unfinished tickets — which is exactly what a
  developer has to do by hand today. Fixing it at survey time seems stronger because it
  also repairs queues that were closed before the fix ships; doing both is defensible."
  This ticket implements the survey-time fix; whether `close.sh` also clears the stamp is
  undecided and out of scope unless the driving session rules it in.

## Considerations

- The reporter's proposed mechanism — resolve each stamped mission, count `mission_member`
  only on a live one, add a `mission_closed` reason — is recorded here as a **hypothesis**,
  not as step 1's design. Step 1 reproduces and localizes; the mechanism is adopted only if
  the localization supports it.
- Risk of the opposite failure: a ticket that becomes claimable the moment its mission is
  archived changes what an unattended `/implement` picks up. That is the intended repair,
  but it means a mission closed `abandoned` will now surface its unfinished tickets as
  ordinary backlog — arguably right (the work was never withdrawn, only the grouping), and
  worth naming in the Final Report so the operator is not surprised by a queue that grows.
- Nothing about this is silent today: the exclusion is reported. The defect is that the
  reason misdescribes the state, so a fix that only adds a comment would not close it.
