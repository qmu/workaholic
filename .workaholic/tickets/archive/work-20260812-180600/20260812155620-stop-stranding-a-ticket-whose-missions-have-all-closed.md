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

## Final Report

Development completed as planned. The reporter's hypothesised mechanism survived
localization and was adopted; the one place this diverges from their sketch is where the
repaired case is reported (see the shape ruling below).

### The reproduction, recorded before the fix

A throwaway repository with `m-live` in `missions/active/`, `m-closed` in
`missions/archive/`, and three todo tickets (naming the closed mission, the live one, and
both). `plan-units.sh` before the change:

```
"backlog": []
"excluded": [ {20260729000001-stranded.md, "mission_member"},
              {20260729000002-live-member.md, "mission_member"},
              {20260729000003-mixed.md, "mission_member"} ]
"missions": [ {"slug": "m-live"} ]
```

The stranded ticket is excluded `mission_member` while `m-closed` contributes no unit —
offered by neither path, exactly as reported. After the change, the same fixture:

```
"backlog": [ {20260729000001-stranded.md, "mission_closed": "m-closed"} ]
"excluded": [ {20260729000002-live-member.md, "mission_member"},
              {20260729000003-mixed.md, "mission_member"} ]
```

### Localization: which of the two halves the fix changes

Both halves confirmed independently. (a) The ticket loop excluded on a merely **non-empty**
relation, consulting no mission state (`plan-units.sh`, at the `read-relation.sh` call).
(b) The mission loop enumerates `.workaholic/missions/active/` only, so an archived mission
contributes no unit — confirmed by `m-closed` being absent from `missions[]` above.

**The fix changes (a) only.** (b) is not a defect: the active area *is* the set of drivable
missions (K1 — the area is the authority), and widening it to archived missions would offer
closed missions as claimable units, which is the opposite of what closing one means. The
premise (a) rests on is what expired, so (a) is where it is repaired.

`grep` over the reference docs and the suite found no consumer of `mission_member` as a
signal beyond documentation and two test sites, both retained (below).

### Open Decision — resolved: survey-time only, `close.sh` untouched

Ruled **out of scope**, deliberately and not by default:

- The survey-time fix is strictly stronger on coverage — it repairs every queue already
  closed before this ships, which a close-path change cannot reach by construction.
- Clearing the stamp at close time **destroys information**. The `mission:` relation is the
  durable record of which mission a ticket belonged to; `/report`, `/ship`'s deferred-concern
  extraction, and the mission graph all read it as history, and an archived ticket's relation
  is read long after its mission ends. Repairing an offer must not cost the provenance.
- It would also make closing a mission a **queue-mutating act**. `close.sh` is the only
  writer of an end state, and that narrowness is the reason it is trustworthy; having it
  rewrite N tickets as a side effect is a much larger blast radius than the defect warrants.

"Doing both is defensible" — but only the survey half is *needed*, and the close half has a
real cost, so it is not done. The stamp is now preserved **and** surfaced: a repaired row
carries `mission_closed`, so the developer who used to clear the stamp by hand no longer has
to, and nothing is lost by leaving it.

### The other ruling the Gate asks for: where the repaired case is reported

The reporter suggested `mission_closed` as an `excluded` reason. It is instead an
**annotation on the backlog row** (`"mission_closed": "<comma-separated closed slugs>"`,
empty for a ticket naming no mission). `excluded[]` is defined as "items the survey saw and
dropped"; a repaired ticket is *offered*, so recording it as an exclusion would state the
opposite of what happened, and a caller filtering `excluded[]` would double-count it. The
annotation keeps both halves honest — the offer says what it offers, the row says why it
once did not. A dangling slug reads as closed for the same reason a closed one does: a
mission that resolves nowhere cannot offer the ticket a unit either.

### Where liveness is answered

A new pure reader, `mission/scripts/read-active-relation.sh`, beside `read-relation.sh`
whose contract is untouched (four seams depend on it). It keys on the **area**, never on
`status` — which is what keeps `/propose`'s safety property intact: a ticket proposed under
a `status: draft` mission still sitting in `active/` remains unclaimable. It never invokes
`missions_migrate_layout` (that function does `git mv`/`git add`), because `plan-units.sh`
must stay side-effect free — it runs inside claim worktrees.

### The many-valued relation

The test is **ANY, not ALL**: a ticket naming one live and one closed mission is still
`mission_member`, arrives through the live mission's unit, and is never double-offered.
Pinned in both directions by the new case.

### Operator-visible consequence, named as the ticket asks

A mission closed **`abandoned`** now surfaces its unfinished tickets as ordinary backlog.
That is the intended repair — the work was never withdrawn, only the grouping — but it means
an unattended `/implement` will pick up work that a developer may have considered dropped.
The queue growing after a mission is abandoned is correct behavior, not a regression. A
developer who genuinely wants that work gone should ice the tickets or drop the relation;
both are already developer-curated acts. Recorded in `docs/drive-loop-runbook.md` so an
operator meets it there rather than in a surprising tick.

### Discovered Insights

- **Insight**: `excluded[]` in `plan-units.sh` carries two different kinds of reason, and
  only one of them is a fact about the artifact. `owned_by_other` and `claimed_*` are
  observations; `mission_member` is a **premise about a future offer** ("it arrives inside
  its mission's unit instead"). A premise can expire while the artifact is unchanged, which
  is precisely how this defect stayed invisible — the survey kept reporting a reason that
  had been true when it was written.
  **Context**: Worth checking any future exclusion reason against this distinction before
  adding it. A reason that promises another path must also own that path's liveness, or it
  becomes a silent drop the moment the other path narrows.

- **Insight**: The propose-safety test at `testProposeWidenedBatch` is explicitly labelled
  the tripwire for narrowing this exclusion — and it stayed green *because* liveness keys on
  the area rather than on `status`. Had the fix read `status: active`, that draft mission
  would have read as closed and every proposed ticket would have become claimable before its
  mission was driven.
  **Context**: K1's "the area is the authority, not a status word" is not only about the
  mission offer; it is load-bearing for the ticket offer too. Any new mission-state predicate
  should key on the area for the same reason.
