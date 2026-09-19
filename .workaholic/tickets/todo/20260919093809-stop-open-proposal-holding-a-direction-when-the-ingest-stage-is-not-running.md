---
created_at: 2026-09-19T09:38:09+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: never-let-the-routine-that-originates-work-converge-on-silence
merge_policy:
verification_handoff:
---

# Stop open_proposal holding a direction when the ingest stage is not running

## Overview

Operator's ask: **issue #907**, item 2 — *`open_proposal` should not hold indefinitely; a proposal
that has sat un-ingested past a plain measure of the loop's own turn is evidence the next stage is
not running, and holding the origination gate on it makes one dead routine silence two.*

**Established against this tree, not taken from the title.** `survey-strategies.sh:665` refuses a
row `open_proposal` on membership alone — `($held | index($w.slug))` — where `$held` comes from
`list-open-proposals.sh`, whose rows carry `number`, `url`, `strategy`, `move` and `title` and
**no timestamp at all**. So there is no age term to relax; the gate is a pure set-membership test
and the set only empties when the proposal's pull request merges.

**The gate's own header states the premise this ticket falsifies**
(`list-open-proposals.sh:20-32`): *the two gates hand off with no window between them … so "one
proposal per strategy in flight at a time" is enforced continuously without a cursor, a stored
timestamp or a per-day bound.* That reasoning is exactly right **while `/specificate` runs**. It
says nothing about the case where it does not, and in that case the handoff never happens and the
gate holds forever. Measured: four directions locked for four hours behind proposals nothing was
ingesting.

**The repair must not be a clock.** A per-day bound is refused by that same header, and a fresh
staleness constant is the tunable this repository refuses by name (`workaholic:propose`, *The
threshold is not a threshold*). What is available instead is a **proof from the tree**: whether the
ingest stage has run at all since the proposal opened. `/specificate` leaves evidence on every
successful run — a `[Proposal]` pull request and the feedback record it registers — so *has
anything been ingested since this proposal opened* is answerable without a network call beyond the
one the gate already makes, and without a stored timestamp.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/observability.md` — a gate that stops holding must say
  so on the row; a silently lifted brake is worse than a stuck one
- `workaholic:implementation` / `policies/test.md` — the new reading and both refusals are pinned
  hermetically, offline, over a fabricated tree

## Key Files

- `plugins/workaholic/skills/propose/scripts/list-open-proposals.sh` (lines 80-100) — the remote
  half of the brake. Its `--jq` projection is where a proposal's own `created_at` would join the
  row; it currently selects `number`, `html_url`, the marker line and `title`.
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` (line 665 and the refusal
  ladder around it) — the one place `open_proposal` is decided. The ladder's order must not move:
  `wip_limit` stays last, and `attribution_unreadable` stays a refusal.
- `plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` — how the ingest stage's
  own evidence is read today (`already_planned`, `captured_on_branch`); the proof in step 3 should
  compose what already exists rather than adding a second walk.
- `plugins/workaholic/skills/specificate/reference/workflow.md` (step 10) — what a successful
  ingest leaves behind: a `[Proposal]` pull request carrying `Closes #<N>`.
- `plugins/workaholic/skills/propose/SKILL.md` — the gate's prose home; *`work_waiting` +
  `open_proposal` are one gate in two halves* must be updated in the same change, because this
  ticket falsifies the sentence *the handoff is window-free by construction*.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Reproduce the reading before changing it.** Run `list-open-proposals.sh` and
   `survey-strategies.sh` in this checkout and record, for every refused row, which refusal fired
   and from which term. Keep that as the before-state: the acceptance below requires every row's
   refusal to be byte-identical except the one this ticket is about.
2. **Decide and state the proof** — this is the ticket's real content. The candidate is *the
   ingest stage has left no evidence since this proposal opened*. Establish, by reading
   `list-inbound-issues.sh` and `reference/workflow.md` **in full**, what evidence a successful
   `/specificate` run always leaves on the base, and pick the one that is a **proof** rather than a
   judgement (it cannot become false by looking again). Write the chosen proof and the two rejected
   candidates into the script's own header.
3. **Carry the proposal's own age as evidence, not as the gate.** Add `created_at` to
   `list-open-proposals.sh`'s projection and render it on the row. It is reported so a reader can
   see how long the hold has stood; the **decision** is the step-2 proof, never the age. A `null`
   timestamp is rendered null and never zero.
4. **Relax exactly one term.** In `survey-strategies.sh`, `open_proposal` holds when the strategy
   is in `$held` **and** the step-2 proof does not hold. When the proof holds, the row is not
   refused `open_proposal`, and it carries a named reading — `open_proposal_uningested` with the
   proposal's number and age — so a reader sees *why* a direction that had an open proposal became
   eligible again. No other refusal, no `pace`, `overdue`, `expiring`, `dormant`, `quiescent`,
   sort or `selected` term moves.
5. **A proof that could not be read holds the gate.** An unreadable or ambiguous reading leaves
   `open_proposal` refusing exactly as today, named by its own reason. *A gate that cannot be read
   is not a gate* cuts the other way here: the brake's failure-safe direction is to keep braking,
   which is what `list-open-proposals.sh`'s own `ok: false` already does for the whole tick.
6. **Update the prose in the same change**: `workaholic:propose`'s *one gate in two halves*
   paragraph and `list-open-proposals.sh`'s header, both of which currently assert the window-free
   handoff as unconditional. Say what is now true, why the old sentence held only while the ingest
   stage ran, and that no per-day bound and no staleness constant were introduced.
7. **Hermetic rows** over a fabricated repository: a held strategy whose proposal the ingest stage
   has evidence of still refuses `open_proposal`; one whose proposal has no such evidence is
   eligible and carries the named reading; a degraded proof refuses; `created_at` renders on the
   row and is null-safe; and every other row in a fixture with no open proposals is byte-identical
   to the pre-change survey.
8. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
   `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The relaxation is decided by a **proof re-derived at the moment of the read**, not by an elapsed
  time; no new numeric constant, no environment variable and no stored timestamp is introduced.
- A strategy held by a proposal the ingest stage has provably not run against is **eligible** and
  its row names why.
- A strategy held by a proposal the ingest stage has evidence of is still refused `open_proposal`.
- A proof that could not be read leaves `open_proposal` refusing, named by its own reason.
- `wip_limit` remains last in the ladder; `work_waiting`, `attribution_unreadable`, `not_active`,
  `not_mine`, `past_target_date` and `no_feedback_refs` refuse exactly as before.
- A survey over a fixture with **no** open proposals is byte-identical to the pre-change survey.
- `open-proposal.sh` is byte-identical to `origin/main`: this ticket changes reading, never writing.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and the new rows fail when reverted.
- `git diff origin/main -- plugins/workaholic/skills/propose/scripts/open-proposal.sh` is empty.
- `grep -n` over the diff shows no added numeric literal used as a threshold and no new
  `WORKAHOLIC_*` variable.
- The before/after survey capture from step 1 differs on exactly the rows the fixture intends.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The chosen proof, and the candidates rejected against it, are written into the script's header.
  A relaxation whose justification exists only in the pull request does not pass.
- The suite is green and the bundle rebuild is diff-clean.
- POSIX `sh` throughout.

## Considerations

- **Relaxing this gate widens what may be originated, so the other brakes matter more, not less.**
  `work_waiting` still holds a direction whose work is queued, and the repository-level
  `WORKAHOLIC_WIP_LIMIT` still holds divergence. Neither may be touched here.
- **The opposite failure is two proposals for one direction.** If the proof is wrong in the
  permissive direction, the loop opens a second proposal against a direction already being
  answered. That is why the failure-safe direction in step 5 is to keep braking, and why the proof
  must be a tree reading rather than an inference about liveness.
- **A stale-proposal reading is not a stale-proposal act.** Nothing here closes an issue, retires a
  proposal, or edits anything on GitHub. Whether an un-ingested proposal should be closed is a
  person's decision and stays out of this ticket.
