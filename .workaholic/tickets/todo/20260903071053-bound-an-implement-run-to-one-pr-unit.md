---
created_at: 2026-09-03T07:10:53+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-finished-subagent-and-take-the-loop-s-clock-off-it
merge_policy:
verification_handoff: 
---

# Bound an implement run to one PR-unit

## Overview

The concurrency rule permits one `implement` runner and nothing bounds what that runner does
inside its own context. Measured: one agent lived one hour thirty minutes, landed a mission of
eight tickets, then claimed and began a second unrelated mission and planned it inside a context
still carrying the whole of the first. This is precisely the case the fresh-context intention
exists to prevent, and the only one the current rules cannot reach.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/implement.md` — the ceiling for the unattended executor
- `plugins/workaholic/skills/drive/SKILL.md` — the Unified Run: survey → partition → claim →
  drive → report → route → account
- `plugins/workaholic/commands/infinite-development.md` — spawns `implement` every tick, which
  is what makes one unit per run sufficient throughput
- `scripts/test-workflow-scripts.mjs` — pins the command bodies

## Implementation Steps

1. In `commands/implement.md`, state that a run takes **one** PR-unit and ends: the survey and
   the partition are unchanged, and the run claims and drives the first unit the order offers.
2. Say why it is not a throughput loss: `implement` is spawned every tick, and the claim
   protocol refuses a unit another run holds, so the next tick takes the next unit on a fresh
   context.
3. Leave `plan-units.sh`, the claim protocol, the ordering and every verdict word untouched —
   this is a bound on the run, not on the survey.
4. Leave `/drive` (attended) alone: a person watching a run may take several units, and the
   fresh-context argument is about unattended residency.
5. Name the remaining case honestly: one unit can itself be a mission of eight tickets, so this
   bounds context growth across *unrelated* work and not within one mission.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/implement` claims and drives at most one PR-unit per run.
- The survey, partition, claim protocol and ordering are byte-identical.
- `/drive` is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/implement.md`: the one-unit bound is stated in the run contract.
- `node scripts/test-workflow-scripts.mjs` passes.
- `sh scripts/e2e/loop-drill.sh verify-all` reports no new failure.

**Gate** — what must pass before approval:

- No change to `plan-units.sh` or to any claim verdict word.

## Considerations

The report's `N units: X shipped, Y PR'd, Z blocked` reconciliation still reads correctly with
N=1; nothing in the `/goal /implement ok` contract assumes N>1.

## Final Report

**Outcome**: implemented, in the ceiling and in the skill.

**An `/implement` run claims one PR-unit, drives it to its routed end, reports, and ends.** It does
not survey again for a second. If the offer still holds work, that is the next tick's run, on a
fresh context.

**The bound is on claiming a second unit, not on the run's other work** — stated explicitly, because
the run does several things that touch *other* units' claims and none of them claims or drives: the
freshen, the survey, the once-per-run readings, a catch-up, a delivery retry, a stranded
publication. Bounding those would strand exactly the work those acts exist to unstick.

**The cost is stated rather than hidden**: the loop lands one unit per tick, so a full queue drains
over more ticks. That is the trade the ask makes — a plan made inside a context carrying an
unrelated mission is worse than a plan made an hour later on a clean one.

**The terminal token does not move**, and saying so was necessary: a run that drives its one unit
cleanly and leaves a claimable offer behind still reports `pending` through §7's survey row, exactly
as before. `ok` still means *nothing claimable remains*, and a reader must not take the new bound as
licence to call a bounded run `ok`.

**An attended `/drive` is exempt by name.** A person is present and chose what to take, which is the
whole difference; the fresh-context concern is about an unattended runner nobody is watching.

**A note on the run that implemented this.** This very `/implement` run drove **six** units before
reaching this ticket, under an explicit instruction to drain the offer. That is not a violation —
the rule lands with this merge and did not exist while the run was driving — but it is the exact
behaviour the ticket forbids, observed once more, and the next tick's run will be the first bounded
one.

**Verified**: `node scripts/test-workflow-scripts.mjs`.
