---
created_at: 2026-07-28T22:18:04+09:00
author: a@qmu.jp
type: refactoring
layer: [Domain, Config]
effort: 4h
commit_hash:
category: Removed
depends_on: 20260728221803-unify-drive-executor.md
mission: loop-engineering-unified-drive
---

# Retire monitor, trip, and carry

## Overview

Execute decisions I1, I3, and I5: with `/drive` unified, the superseded executors retire **completely** — commands, skills, agents, and their side channels — and their surviving ideas are recorded as relocations, not deletions:

- **`/monitor` (I1/G1)** — parallel worktrees, honest terminal, PR auto-creation, agent-hours, and the front-loading doctrine all live in the unified `/drive` now; the pre-flight's interactive batch is superseded by creation/approval-time `merge_policy` + the claim protocol. Remove `commands/monitor.md`, `skills/monitor/`, and the monitor test suites.
- **`/trip` (I1)** — design discussion belongs to the feedback conversation, decomposition to `/mission`/`/propose`, execution to `/drive`. Remove `commands/trip.md`, `skills/trip-protocol/`, `agents/` (planner/architect/constructor — the only Agent Teams surface), and the trip suites. **`trips/` stays on disk and in the allowlist as read-only history** (knowledge is never deleted; the allowlist is permissive) — documented as a legacy area with no writer.
- **`/carry` (I5)** — in-flight state lives on the claim branch by construction (the next tick re-claims and resumes); carry-over learnings are H3 feedback written at the ship seam. Remove `commands/carry.md`, `skills/carry/`, and the carry suites.
- **The reflection channel (I3)** — `append-reflection.sh`/`list-reflections.sh` and the mission `## Reflection` convention retire; drive-born learnings reach the next planning as `kind: concern`/`insight` feedback (already the live seam). The reserved `concerns: []` mission frontmatter key stops being scaffolded (tolerated on legacy files).

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:planning` / `policies/terminology.md` — "trip", "monitor", and "carry" leave the command vocabulary; the drive SKILL records where each idea went so none is re-litigated
- `workaholic:design` / `policies/history-structures.md` — `trips/` history and archived tickets/stories referencing the retired commands stay verbatim; the record of the retirement points forward
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` for any touched script (applies to all code work)
- `workaholic:implementation` / `policies/objective-documentation.md` — the docs sweep leaves no sentence claiming a retired command exists

## Key Files

- **Deleted**: `commands/{monitor,trip,carry}.md`; `skills/monitor/`, `skills/trip-protocol/`, `skills/carry/`; `agents/planner.md`, `agents/architect.md`, `agents/constructor.md`; `mission/scripts/{append-reflection,list-reflections}.sh`; every monitor/trip/carry test suite and SCRIPTS entry.
- `plugins/workaholic/skills/mission/scripts/{status.sh?,preflight?}` — `monitor/scripts/status.sh` relocates into the drive skill if the unified run's terminal derivation uses it (ticket 221803's truth table); otherwise it retires with the skill — follow what 221803 actually wired.
- `plugins/workaholic/hooks/policy-lens.sh` — the sentinel list drops `/trip` and `/monitor` (now `/ticket`, `/report`, `/ship`, `/drive`, `/propose`? — add `/propose` only if its command carries the sentinel; do not add sentinels in this ticket).
- `plugins/workaholic/skills/mission/SKILL.md` + `commands/mission.md` — remove `/monitor` hand-off language (bare `/mission`'s step 5 recommends `/goal /drive ok` now), reflection references, `concerns: []` scaffolding; the reorganize-and-carry prose keeps `carried` (a **close.sh outcome**, untouched) but drops references to the `/carry` command.
- `plugins/workaholic/skills/{report,ship,catch,branching,gather}/…` — grep-driven sweep of monitor/trip/carry references (e.g. `list-worktrees.sh` trip wording, `/catch`'s missions view text, ship's trip routing section — `/ship`'s worktree/unknown context routing now describes claim worktrees instead of trip worktrees).
- `plugins/workaholic/agents/` removal also empties the Agent-Teams paragraphs in `CLAUDE.md` (component nesting table's exemption row, "No Per-Workflow Agent Files" caveat).
- `plugins/workaholic/rules/workaholic.md` — `trips/` row annotated "legacy, read-only history (no writer since 2026-07-28)".
- `scripts/build-plugins/*` — confirm the build closure drops the removed skills from `outputs/workflows` (trip was already excluded; monitor/carry were not built — verify, don't assume).
- `scripts/test-workflow-scripts.mjs` — suites removed; the monitor-contract prose sentinels that moved into the drive SKILL follow their text (221803 already re-pointed them; this ticket deletes the leftovers).
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` — full sweep: executor paragraphs, command tables, the `/trip` marketing in README, `.workaholic/README`'s missions bullet, the mermaid maps' trip/monitor nodes.

## Implementation Steps

1. Delete the three command files, three skills, three agents, and the reflection scripts; relocate `monitor/scripts/status.sh` only if 221803 wired it.
2. Grep-sweep `plugins/` + docs for `monitor|trip-protocol|/trip|/carry|reflection` and fix every live reference (history under `.workaholic/` stays verbatim).
3. Update the policy-lens sentinel list and the hooks documentation lines in `CLAUDE.md`/plugin.json.
4. Update `rules/workaholic.md` (`trips/` legacy annotation); run `layout-doctor.sh .` — `trips/` stays conforming.
5. Remove the dead test suites + SCRIPTS entries; full suite green.
6. Docs sweep; argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record I1/I3/I5); verification depth ruling: hermetic suite + grep gates, per repo precedent.

**Acceptance criteria**

- `commands/`, `skills/`, and `agents/` contain no monitor/trip/carry surface; `grep -rn "workaholic:monitor\|workaholic:trip-protocol\|workaholic:carry\|/monitor\|/trip\|/carry" plugins/ CLAUDE.md README.md` returns only historical/relocation records.
- The reflection channel is gone (`append-reflection`/`list-reflections` deleted; no scaffolded `concerns: []`); drive-born learnings are documented as H3 feedback.
- `trips/` remains allowlisted, annotated legacy; `layout-doctor.sh .` conforming.
- The suite is green with the dead suites removed and no orphaned SCRIPTS entries; `outputs/workflows` carries no removed skill.
- Docs updated in the same change — the command tables list exactly: ticket, request, drive, commit, propose, feedback, report, ship, mission, catch, explain, workaholify.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green; build + verify + validate-metadata green; posix-lint conforming; layout-doctor conforming.

**Gate**

- Suite green and the grep gates empty of live references; the bare `/mission` session's hand-off names `/goal /drive ok`.

## Considerations

- **Record relocations, not absences**: the drive SKILL's Unified Run section (221803) is the forward pointer for every absorbed idea; this ticket only removes and re-points — if an idea has no new home, stop and add it to 221803's section rather than deleting it silently.
- Archived tickets, stories, and the `trips/` tree reference the retired commands throughout — history is grandfathered, never edited.
- `/catch` stays (read-only reporting is untouched by the executor merge); only its prose about `/monitor`'s in-flight view needs re-pointing at claim branches.
- The user-level `enabledPlugins` may still cache old command lists in live sessions until plugin refresh; note it in the ship story's post-release instructions, not in code.

