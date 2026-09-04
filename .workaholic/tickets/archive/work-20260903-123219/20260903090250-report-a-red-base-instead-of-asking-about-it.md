---
created_at: 2026-09-03T09:02:50+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-red-base-impossible-for-the-loop-to-miss
merge_policy:
verification_handoff: 
---

# Report a red base instead of asking about it

## Overview

`base-health` announces a red base as a `base-red:<sha>` question, and `ask-question.sh` holds
questions under `quiet_hours` (22–08) because a question addresses a named person and nobody
should be paged at 23:00 to choose between two dates. A red base asks the operator to decide
nothing — it reports that the ground everything is landing on is broken — so the reason the quiet
window exists does not apply to it. `🔴 Blocked` already exists for that class and is governed by
its own failure-signature cool-down. This ticket moves the red base onto it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-base-health.sh` — where the question is composed today
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` and `lib/speaking-window.sh` — the hold this leaves
- `plugins/workaholic/skills/notify/SKILL.md` — the `🔴 Blocked` shape and its cool-down
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's spec and its question key
- `CLAUDE.md` — the red-alert cool-down paragraph and the `/moderate` step table

## Implementation Steps

1. **Reproduce and localize first.** Establish the current path end to end: which key is asked,
   which gate held it, and what the `🔴 Blocked` cool-down's own expiry rule is. Quote both.
2. Emit the red base as a `🔴 Blocked` report under the existing cool-down, composing that rule
   rather than re-deriving it — a second copy of the clock gate is how copies drift.
3. Retire the `base-red:<sha>` question, or state deliberately why it survives beside the report;
   two announcements of one fact is the noise this repository has twice retired roots for.
4. Keep the attribution walk untouched: who broke it is still `attribute-base-red.sh`'s answer and
   still rides the report.
5. Update the step table, the step's spec and `CLAUDE.md` in the same change.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A red base reaches the channel as `🔴 Blocked`, governed by the existing failure-signature cool-down and not by `quiet_hours`
- The cool-down rule is composed from its existing derivation, not re-derived
- The `base-red` question is either retired or its survival is stated with its reason

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all` for the drills covering the tick's posting gates

**Gate** — what must pass before approval:

- The suite and the classified drill set pass, and no second copy of the speaking-window derivation exists

## Considerations

- Breaking a quiet hour is the point here, and it is bounded by the cool-down rather than by a new
  threshold; introducing one would be a constant nobody can defend.
- The ask does not say whether the `base-red` question should survive alongside the report. Step 3
  decides it out loud rather than silently.

## Final Report

**Outcome**: implemented.

**Reproduced and localized first, and both rules quoted.** The path was: `step-base-health.sh`
composed a `needs` payload whose `key` was `base-red:<commit>`; `step-human-checkin.sh` drained it;
and `ask-question.sh` held it under `WORKAHOLIC_QUIET_HOURS` (default `22-08`) and
`WORKAHOLIC_WORK_DAYS` through `lib/speaking-window.sh`. The `🔴 Blocked` cool-down's own expiry is
*the earlier of 24 hours after the first report and the start of the next working day* — the first
hour inside `WORKAHOLIC_WORK_DAYS` at the end of `WORKAHOLIC_QUIET_HOURS`, in
`WORKAHOLIC_QUIET_TZ` — composed from the check-in gate's own terms rather than re-derived.

**The red base now emits a report.** The step's payload names
`report_the_red_base_as_a_blocked_alert` with `shape: "🔴 Blocked"` and a `signature`, and its
`bound` states in its own words that it is addressed to nobody, is **not** held by `quiet_hours` or
`WORKAHOLIC_WORK_DAYS`, and is deduped under the existing cool-down — **composed, never
re-derived**, so no second copy of the clock gate exists.

**The signature carries no SHA**, which is the cool-down's own rule (`never a SHA, a timestamp, a
file count`) and not a new choice: a key that changes every commit suppresses nothing. It is the
failing check names, so *the same suite still failing* is one alert however many red commits carry
it, and a newly broken suite opens a fresh root.

**Step 3's decision, made out loud: the `base-red:<commit>` question is retired**, not kept beside
the report. Two announcements of one fact is the noise this repository has twice retired status
roots for, and the report is strictly the better of the two — it reaches the channel when the base
breaks instead of the next working morning. The row's `key` is now empty, so no question is drained
for it.

**The attribution walk is untouched**: who broke it is still `attribute-base-red.sh`'s answer, and
the commit, its pull request and its author still ride the report's own sentence.

**Documentation updated in the same change**: the `/moderate` step table's key and addressee columns
in `CLAUDE.md`, the red-alert cool-down paragraph there, `notify/SKILL.md`'s dedup rule, the step's
spec in `moderate/reference/workflow.md`, and the base-checks consumer sentence in
`drive/reference/claims.md`.

**Suite addendum.** Three rows pinned the retired question and were rewritten to the new contract in
the same change: the red-base row now asserts the payload carries **no** question key, names
`report_the_red_base_as_a_blocked_alert` with the `🔴 Blocked` shape and a signature of the failing
check names (**no SHA**), and that its own `bound` says the quiet window does not hold it; the
`unattributable` row asserts the same keyless report. Nothing was loosened — each assertion is
strictly more specific than the one it replaced.
