---
created_at: 2026-08-26T11:32:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Stop asking about a finished claim

## Overview

PROPOSED. Ticket 7 of 8, and two changes to one step for one reason: the question channel
is being spent on things that are not questions.

First, `step-stalled-units.sh` drops a `superseded` row from its question set and reports
it as a finding in the tick log instead. A person is currently being asked to look at
three merged pull requests, and a question layer that cries wolf is worse than none —
the asked-once ledger means the real stalled unit arrives in a stream a person has
learned to skip.

Second, separate the step's log-facing `summary` from its root-facing `event`. The summary
embeds an age in hours that increments every tick, so the moderation diff calls the step
changed hourly and the root has restated the same stalled units four times today — the
shape `📦 Release Preparation` was retired for.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — both changes.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — READ. It renders
  `event` and diffs on `summary`; this is why the two must differ.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the step's input.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step's contract.
- `scripts/test-workflow-scripts.mjs` — the question set and the diff stability.

## Implementation Steps

1. Read `render-tick-post.sh` and the 2026-08-23 `event`-versus-`summary` rule. The
   renderer normalises a timestamp, a bare hex object name and a clock time out of both
   sides — and **only** those — so an age in hours is not normalised away and must not be
   in the summary the diff reads.
2. Drop `superseded` rows from the question set, and report them in the tick log as a
   finding instead. A finished claim is a fact, not a question.
3. Give the step an `event` distinct from its `summary`, with the age kept out of whatever
   the diff compares. A step with no finding supplies no event, so no root line renders.
4. Confirm the asked-once keying is untouched: `stalled-unit:<unit>` still keys a genuine
   stall, and this ticket changes only which rows reach it.
5. Update `SKILL.md` for both halves.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No question is emitted for a `superseded` claim; it appears in the tick log instead.
- Two consecutive ticks with an unchanged stalled set produce no root line the second
  time.
- A genuinely stale, unmerged claim still produces its question, keyed once.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the question set, and a two-tick diff with an
  unchanged set.
- `sh scripts/e2e/loop-drill.sh verify-moderate`

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.

## Considerations

- The two halves are one change because they share a cause — the step announcing what is
  not news — and because splitting them would leave the root restating a set the first
  half just shrank.

## Final Report

Development completed as planned. Two changes to one step, for the one reason the ticket names:
the question channel was being spent on things that are not questions.

**A `superseded` claim never reaches the question set.** Its work already reached the base, so
there is nothing for a person to look at and nothing for them to decide. It is counted in the
summary as `N finished (superseded)` — a fact, in the place facts belong. The cost of getting
this wrong is not neutral and is worth restating: the asked-once ledger means the one *real*
stalled unit then arrives inside a stream a person has learned to skip.

**The age left the summary, and that is a correctness fix rather than a tidy-up.** The
moderation root calls a step changed when its summary differs from the same step's an hour ago,
and `render-tick-post.sh` normalises out a timestamp, a bare hex object name and a clock time —
and **only** those. `oldest stopped 27h` survives normalisation and increments every tick, so
this step was changed *hourly by construction* and the root restated the same stalled units four
times in one day: exactly the shape `📦 Release Preparation` was retired for. The age is still
computed and still reaches the person, in the question that names the unit.

**The `event` is now distinct from the `summary`** and carries no age either, for the same
reason: the root is read by someone scanning a channel, who needs *N claimed units have not
moved for a day or more*, not the tick's bookkeeping. A step with no stalled unit supplies no
event and renders no line, and a tick whose only finding is a finished claim renders none
either — nothing happened *to* the repository.

**The keying is untouched.** `stalled-unit:<unit>` still keys a genuine stall; only which rows
reach it moved. The test asserts the key is stable across ticks, exactly as before.

**Measured on this repository after the change**: 7 claimed units, 4 of them finished
(superseded) and silent, 1 genuine stall producing its one question — where all five would
previously have been asked about.

### Discovered Insights

- **Insight**: The step's own test needed `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0` as well
  as `WORKAHOLIC_CLAIM_STALE_HOURS=0`, because `claim_active` short-circuits the verdict chain
  before `superseded` and a claim created seconds ago never reaches the verdict under test.
  **Context**: `stale` and the heartbeat window are different clocks answering different
  questions — *should a human look* versus *is a run still working it* — and a fixture about a
  late-chain verdict has to open both. Opening only the first produces a claim that is reported
  stale and still reads `claim_active`, which is a coherent state and not the one being tested.
- **Insight**: A counter in a step's `summary` is load-bearing for the moderation diff, not just
  for a human reading the log. Anything monotonic in it — an age, an elapsed time, a running
  total — makes that step permanently "changed".
  **Context**: The renderer's normalisation list is deliberately short (timestamp, hex object
  name, clock time), so it cannot be relied on to absorb a new monotonic value. The rule for any
  future step is the same one applied here: the summary moves when the *finding* moves, and
  everything else goes in the question or the log line that names the item.
