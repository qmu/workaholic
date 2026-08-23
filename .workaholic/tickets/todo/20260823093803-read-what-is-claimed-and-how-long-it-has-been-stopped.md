---
created_at: 2026-08-23T09:38:03+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: route-a-stalled-unit-to-a-person-who-is-asked-by-name
merge_policy:
verification_handoff: 
---

# Read what is claimed and how long it has been stopped

## Overview

`/moderate`'s check-in asks only about what its own steps found, and no step reads the state of
claimed work. So the one surface in this plugin that names a person and notifies them cannot
learn that a unit has been blocked for eleven ticks.

The reading it needs already exists in pieces. `plan-units.sh` reports `claimed[]` and
`resumable[]` with `stale`, `resume_reason` (`heartbeat_lapsed` / `parked_with_pr`) and
`last_commit_at`; `list-claims.sh` treats unmerged remote branches as the only claim oracle. What
is missing is a step that composes them into *this unit has not moved for N hours*.

This ticket adds only the reading; the asking is the sibling's subject, so this one lands and
changes no observable behaviour.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-strategy-pace.sh` — the precedent, and the
  shape to follow: a tick step that calls another skill's script directly, because the run that
  produced the state writes nothing into the tree and cannot hand anything over.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `claimed[]` / `resumable[]`, their
  `stale` flag and `last_commit_at`.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the claim oracle and the heartbeat's
  meaning; read it before deriving any age.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — `STEPS`, where the new step registers.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — every step has a stated contract;
  the suite fails if a step in `STEPS` has no section.

## Implementation Steps

1. **Reproduce before designing.** Take a unit whose claim branch exists and whose heartbeat has
   not advanced for hours, and confirm from `run.sh` that no step reports it — establish the gap
   from the scripts, not from the report.
2. **Localize.** Confirm `plan-units.sh` already carries everything needed and that the age is
   derivable from the claim branch tip, so nothing new is stored and no second oracle appears.
3. Add a step that returns, per claimed unit: the unit id, its branch, its owner, how long since
   the branch last moved, and whether it has an open pull request. **Compose the existing
   readers; do not re-derive a claim from git directly.**
4. Report a degraded read by name (`no_origin`, unreadable survey) rather than as a step that
   ran and found nothing — the standing rule for every reader here.
5. Change no observable behaviour: post nothing, ask nothing, touch no claim.
6. Register the step in `run.sh` and give it a contract section in `reference/workflow.md` in the
   same commit, and update `CLAUDE.md`'s step count.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every claimed unit is reported with its age since the branch last moved and its owner.
- A unit with an open pull request is distinguishable from one with none.
- A degraded read is named; it never renders as "nothing is stalled".
- The tick's posting behaviour is unchanged by this ticket.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A fixture with one fresh claim, one long-stale claim and one claim with a PR.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- Age must come from the claim branch tip, which the heartbeat already advances. Inventing a
  second notion of "last activity" would give the claim protocol two clocks.
- Resist filtering here. What counts as *long enough to matter* is the sibling's judgement; this
  step reports every claimed unit and its age.
