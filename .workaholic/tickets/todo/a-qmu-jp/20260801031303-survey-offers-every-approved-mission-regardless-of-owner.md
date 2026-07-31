---
created_at: 2026-08-01T03:13:03+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on: [20260801031300-survey-never-reports-a-silently-empty-backlog.md]
mission:
merge_policy: auto
claim: work-20260731-195744
---

# The survey offers every approved mission regardless of who owns it

## Overview

`plan-units.sh` filters the backlog by developer — `list-todo.sh` is scoped to
`todo/<user-slug>/` — but applies **no ownership filter to missions at all**. It
walks `.workaholic/missions/active/*/mission.md`, checks `status: approved`, the
acceptance floor, and the ticket-queue floor, and offers whatever survives. A
mission whose `assignees` names somebody else is offered to every runner.

Every other consumer of ownership already reads it through one place. The mission
lens, `list.sh`'s computed `relation`, `summary.sh`, `validate-mission.sh`'s
approved-owner floor, and `ship`'s concern lane all resolve owners through
`mission/scripts/mission-owners.sh` (plural `assignees`, with a legacy fallback
to the singular `assignee`). The executor's own survey is the one consumer that
does not — so the roadmap a developer is shown and the queue their runner drains
disagree about whose work it is.

Measured 2026-08-01 while designing an hourly unattended runner, where it stops
being cosmetic: a routine running as one developer would claim a colleague's
approved mission and drive it to a PR — or, under `merge_policy: auto`, to
`main`.

## Policies

- `workaholic:implementation` / `policies/domain-layer-separation.md` — "who owns this mission" is one domain question and must have one implementation; a second, divergent answer inside the surveyor is the duplication this policy forbids.
- `workaholic:implementation` / `policies/observability.md` — every drop is already reported with a reason in `excluded[]`; a new exclusion must be equally legible, never silent.
- `workaholic:development` / `policies/parallel-long-running-agents.md` — several people and runners share this queue; taking another person's mission is the coordination failure the claim protocol otherwise prevents.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — layout and POSIX `#!/bin/sh -eu` house style.

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` - lines 173-214 walk the active missions with no ownership check
- `plugins/workaholic/skills/mission/scripts/mission-owners.sh` - the single owner resolver every other consumer already uses
- `plugins/workaholic/skills/mission/scripts/list.sh` - computes the `mine`/`unassigned`/`others` relation the bare `/mission` view partitions on
- `plugins/workaholic/hooks/mission-lens.sh` - the always-on nudge, whose ownership gate is the behavior to match
- `plugins/workaholic/skills/drive/SKILL.md` - *Unified Run* §1, which describes what the survey offers
- `CLAUDE.md` - the always-on-mission-lens section states the shared ownership gate; it must stay true
- `docs/drive-loop-runbook.md` - §4 *What feeds the loop*, and the `excluded[]` reason vocabulary in *Failure modes*

## Implementation Steps

1. In `plan-units.sh`, resolve each active mission's owners through `mission/scripts/mission-owners.sh` — never by re-parsing `assignees`/`assignee` inline. The legacy fallback lives in that script and must not be reimplemented.
2. Apply the same gate the mission lens uses: a mission is offerable when the current `git config user.email` is among its owners **or** it is unowned (empty `assignees` = team-owned/claimable). A mission owned solely by others is dropped.
3. Add the exclusion reason `owned_by_other` to the `excluded[]` vocabulary, so an operator reading a cron log sees the drop and its cause rather than an unexplained absence. Keep it distinct from `not_approved`, `no_plan`, `no_tickets`, and `claimed` — the reasons are read straight out of logs and drive different developer actions.
4. Keep an unowned mission offerable, matching the lens ("surfaced to everyone as claimable"). Divergence between the nudge and the executor is exactly what this ticket removes.
5. Update `drive/SKILL.md` §1, `docs/drive-loop-runbook.md` §4 and its failure-mode table, and the `CLAUDE.md` line that lists every consumer reading through `mission-owners.sh` — the executor now belongs on that list. Same commit.
6. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`); both `drive` and `mission` scripts ship into the workflows bundle.

## Quality Gate

**Acceptance criteria**

- An approved, drivable mission whose `assignees` contains only another email is **not** in `missions[]` and **is** in `excluded[]` with reason `owned_by_other`.
- An approved, drivable mission whose `assignees` contains the current identity is offered, including when it lists several owners.
- An approved, drivable mission with empty `assignees` is offered (unowned = claimable).
- A legacy mission carrying only the singular `assignee` resolves identically to the plural form — the fallback is exercised, not bypassed.
- `plan-units.sh` contains no inline parsing of `assignees`/`assignee`; the resolution goes through `mission-owners.sh`.
- The offer set for a given identity matches what `mission/scripts/list.sh` classifies as `mine` or `unassigned` for that identity, over the same fixture.
- `drive/SKILL.md`, `docs/drive-loop-runbook.md`, and `CLAUDE.md` state the executor's ownership gate, in the same commit.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with new hermetic fixtures covering each of the four ownership shapes above (other-owned, self-owned, co-owned, unowned) plus the legacy singular field.
- One assertion compares `plan-units.sh`'s offer set against `list.sh`'s `mine`/`unassigned` partition on the same fixture repository — that equality is the anti-divergence check and is what keeps the two answers from drifting apart again.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — no residual `outputs/` diff.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate**

- The suite is green including the survey-vs-lens equality assertion; without it this fix is a copy of a rule rather than a single source of it.

Decided: unowned missions stay offerable — matching the mission lens and the bare `/mission` view, where unowned is surfaced to everyone as claimable; making the executor stricter than the nudge would hide work that the roadmap actively advertises (developer may override at /drive).

Decided: a new `excluded[]` reason rather than silent omission — the reason vocabulary is read out of cron logs and each value maps to a different developer action; `owned_by_other` means "nothing to do", which is worth being able to see (developer may override at /drive).

Decided: hermetic suite only — the whole surface is fixture repositories and JSON comparison; a live run adds nothing (developer may override at /drive).

## Considerations

- Ownership is resolved from the runner's `git config user.email`, which is the same value the backlog scoping already depends on. A runner with the wrong identity now gets a wrong *mission* offer as well as an empty backlog — one more reason the identity failure must be loud (`20260801031300-survey-never-reports-a-silently-empty-backlog.md`).
- `plan-units.sh` is called inside claim worktrees and must stay side-effect-free; `mission-owners.sh` is a pure read, so this stays true (`plugins/workaholic/skills/drive/scripts/plan-units.sh` header).
- Per-mission subshells already cost a few processes per survey; adding one more resolver call per mission is in the same order, but if a large roster ever makes the survey slow, the fix is a batch reader in `mission/scripts/`, not inlined parsing here (`CLAUDE.md`, always-on mission lens).
- Depends on the survey contract change in `20260801031300-survey-never-reports-a-silently-empty-backlog.md`; both edit `plan-units.sh`'s emitted object and its `excluded[]` vocabulary.
