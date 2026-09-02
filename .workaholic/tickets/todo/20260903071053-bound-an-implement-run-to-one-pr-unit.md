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
