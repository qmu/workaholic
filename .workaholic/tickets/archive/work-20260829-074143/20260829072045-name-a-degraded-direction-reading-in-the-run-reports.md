---
created_at: 2026-08-29T07:20:45+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Name a degraded direction reading in the run reports

## Overview

PROPOSED. `/propose` and `/standup` must name a degraded direction reading rather than
proposing against, or digesting, a blind read. This is the same voice `pace` and `arrived`
already use — evidence in the report, in the vocabulary the layer already has — and it
changes **no gate** that the survey ticket has not already changed. `standup/scripts/
digest.sh` is the second consumer and renders the same fact where the operator reads it in
the morning.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/keep-serving.md` — a degraded read reported as degraded, never as quiet

## Key Files

- `plugins/workaholic/skills/standup/scripts/digest.sh` — reads `attributed-work.sh` per
  strategy; must render a degraded read as degraded, not as a quiet strategy.
- `plugins/workaholic/skills/propose/SKILL.md` — the run report's contract and the refusal
  vocabulary.
- `plugins/workaholic/skills/standup/SKILL.md` — the digest's contract and its no-op reasons.
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md` — the behaviour statements that move
  with this mission.
- `scripts/test-workflow-scripts.mjs`, `outputs/workflows/`.

## Implementation Steps

1. `/propose`'s run report names the degraded reading per strategy, using the refusal the
   survey ticket already emits — no second word, and no report line that implies the tick
   judged something it could not read.
2. `digest.sh` renders a degraded strategy **by name** rather than as an "no activity" line:
   a quiet direction and one the reader could not see into must not render alike, which is the
   digest's own existing rule for the unattributed count.
3. Keep the digest's no-op reasons honest: a degraded read is not `no_activity`. If every
   strategy read is degraded, say that rather than posting a digest of nothing or suppressing
   the morning silently.
4. **Change no gate here.** Eligibility, the sort, `selected`, the caps and the posting gates
   are byte-identical; this ticket only names what is already true after the survey ticket.
5. Update `CLAUDE.md` and `rules/workaholic.md` in the same change — the current text states
   `no_citing_artifacts` is *explicitly not a refusal* and that the attribution reader is
   *lossy, not silent*; both need the new term to stay accurate.
6. Hermetic cases over a degraded and a healthy strategy for both surfaces; regenerate
   `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/propose`'s report names a degraded direction reading, in the existing vocabulary.
- The digest renders a degraded strategy distinctly from a quiet one, and never as
  `no_activity`.
- No gate, sort, cap or posting rule moves in this ticket, proved by a byte-diff over a healthy
  fixture.
- `CLAUDE.md` and `rules/workaholic.md` state the new behaviour in the same commit.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose` and `verify-standup` still green.
- A byte-diff of the survey's `refusal`/`selected` over a healthy fixture, before and after.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `Outputs Freshness` shows no diff after the rebuild.
- The documentation change is in the same commit as the behaviour, not deferred.

## Considerations

- `/standup` is a pure read and must stay one: nothing here may add a write, a commit or a
  GitHub call to it.
- The report is read by nobody on the day it matters, which is why the survey ticket carries the
  actual brake and this one carries only the naming. Do not compensate by adding a question here
  — reaching a person is `/moderate`'s job and belongs in its own ask if it is wanted.

## Final Report

Development completed as planned.

`/propose`'s run report step now names every strategy the survey refused
`attribution_unreadable` — the word the survey already emits, no second one — and states in
the same breath that it may not print a `pace`, a `dormant` or a `quiescent` verdict for
such a strategy, because the survey emits none and a line implying the tick judged what it
could not read is the exact collapse the mission removes.

`digest.sh` carries `readable` and the reader's own `reason` on every strategy record,
`degraded_count` beside the other counts, and `attribution_unreadable:<slug>` in `errors[]`.
Before this a degraded strategy rendered **exactly** like a quiet one — same empty `moved`,
same empty `waiting`, `active_count` null so it never counted as active — and fell into the
`no_activity` silence.

Two no-op rules follow from that:

- **Every** strategy degraded is its own named no-op, `all_attribution_unreadable`, sitting
  beside `strategy_list_unreadable`. A **partial** degradation is deliberately not a no-op:
  the strategies that were read still have a morning, and the degraded ones are named in it.
- The **honesty line goes null** when any walk failed. `unattributed` is derived by
  *subtracting* what the strategies attributed, so a direction whose walk failed pushes its
  own work into that figure — an over-report for a reason that has nothing to do with
  attribution.

No gate, sort, cap or posting rule moved: the brake is the survey's and was landed by the
previous ticket, and `/standup` stays a pure read — no write, no commit, no GitHub call was
added. `CLAUDE.md` and `rules/workaholic.md` are updated in this commit, as the gate
requires, together with `workaholic:propose` and `workaholic:standup`.

Drills: `verify-propose` 15/15, `verify-standup` 3/3 (1 advisory, pre-existing).

### Discovered Insights

- **Insight**: the digest's `if ! W=$(... attributed-work.sh ...)` guard never fires for a
  degraded walk, because that reader exits 0 by contract.
  **Context**: the record has to be *kept and named* rather than dropped at that guard —
  dropping it would delete the strategy from the morning altogether, which is a worse
  version of the same defect. Any future consumer that treats a non-zero exit as its only
  degradation signal will silently inherit this bug.
- **Insight**: an apostrophe inside a comment in a single-quoted jq program terminates the
  shell string, and the failure surfaces as `jq: syntax error` plus a stray word being run
  as a command.
  **Context**: it bit twice in this mission, in `survey-strategies.sh` and again here. The
  existing code escapes them as `'"'"'`; the cheaper habit is to write those comments
  without apostrophes at all.
