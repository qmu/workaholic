---
created_at: 2026-07-22T08:14:06+09:00
author: a@qmu.jp
type: enhancement
layer: [UX]
effort: 2h
commit_hash:
category: Changed
depends_on: 20260721161212-developer-centric-bare-mission.md
mission:
---

# Bare /mission becomes a readiness session: every assigned mission drive-ready

## Overview

The developer's stated expectation for `/mission` (2026-07-22): running it opens a **working session**, not just a report. The conversation that follows should (a) start from an explanation of the state of the missions assigned to the caller, (b) proceed through the replans any of them need — taking the developer's questions and rulings as it goes — and (c) aim at one explicit end state: **every mission assigned to this developer is drive-ready** (non-empty plan, `drive_authorized`, ordered queue in its worktree).

The dependency ticket (`20260721161212`) already turns the bare listing into the developer-centric tiered view; this ticket makes that view **step one of a flow** rather than the whole behavior:

1. **Status explanation** — render the tiered view, then explain (prose, from the data already returned): each assigned mission's progress, next acceptance item, drive-authorization state, and what blocks readiness (`not_authorized`, `no_plan`, `0/0`, no worktree, stale plan). The readiness facts come from the existing readers (`list.sh`/enriched fields, `drive-authorized.sh`'s per-mission floor as `preflight.sh` mirrors it) — no new state stored.
2. **Replan loop** — for each assigned mission that is not drive-ready, offer to run its **existing replan flow** now, one mission at a time, in the mission's own worktree (creating it via `create-mission-worktree.sh` when absent). The interrogation asks only genuine design rulings (the Recommended-label test governs); mechanical fixes are decided-and-recorded. The developer can defer a mission ("leave it") — that is recorded, not re-asked in the same session.
3. **Readiness reconciliation** — the session ends with an explicit line: `N/M assigned missions drive-ready`, naming each mission left short and why (deferred by the developer, or blocked on a named ruling). Honest-terminal doctrine: the line is derived from the same readers, never asserted.
4. **Execution hand-off is `/goal /monitor ok` — never `/drive`** (developer ruling, 2026-07-22). The developer runs this session from the **root** worktree; a bare `/drive` there is ambiguous — it naturally reads as a drive of the main tree, not of the mission worktrees just made ready. The signal for executing the readied missions — per-worktree, in parallel, over a long unattended stretch at any hour, with no further questions — is `/goal /monitor ok`. The session's closing prose recommends exactly that command and does not mention `/drive` as the next step.

## Policies

- **Design / modeless-design** — no new subcommand: the bare argument routes to this session; deeper steps emerge from the conversation.
- **rules/interaction.md (decide-and-record)** — within the session, only genuine replan rulings become questions; everything derivable is decided and recorded in the mission artifacts.
- **Implementation / observability** — readiness is computed from the existing scripts each time; the reconciliation line mirrors `/monitor`'s honest-terminal shape.
- **Thin commands, comprehensive skills** — the flow is command prose orchestrating existing skill machinery (replan flow, worktree creator, readers); any new conditional logic goes into a mission script, never inline shell.

## Key Files

- `plugins/workaholic/commands/mission.md` — restructure the bare-argument section into the three-step session above; the replan loop references the existing "Referencing an existing mission — replan" flow rather than restating it.
- `plugins/workaholic/skills/mission/SKILL.md` — document the session contract (status → replan loop → reconciliation) and the readiness definition in one place; built skill → rebuild `outputs/`.
- `plugins/workaholic/skills/monitor/scripts/preflight.sh` — reuse as the readiness reader if its eligibility output fits; if a lighter mission-scoped reader is needed, add it under `skills/mission/scripts/` (POSIX sh, additive JSON).
- `CLAUDE.md` / `README.md` — `/mission` row: the bare command is the readiness session.

## Related History

- `20260721161212-developer-centric-bare-mission.md` (dependency) — the tiered status view this session opens with; `summary` retirement already decided there.
- Mission replan flow (`work-20260716-*` era) and `/monitor` pre-flight eligibility — the machinery this session sequences interactively.

## Implementation Steps

1. Rewrite the bare-`/mission` command section into the session flow (status explanation → per-mission replan offers → reconciliation line).
2. Wire readiness facts from the existing readers; add a mission-scoped readiness script only if `preflight.sh` proves too monitor-shaped.
3. Update SKILL.md, CLAUDE.md, README.md; rebuild `outputs/`; run the verification suite.

## Quality Gate

- `node scripts/test-workflow-scripts.mjs` green; if a new readiness script is added, hermetic fixtures pin its JSON (drive-ready vs not, per blocker class).
- `node scripts/build-plugins/build.mjs` then clean `outputs/` porcelain; `verify.mjs` + `validate-metadata.mjs` pass.
- Doc truthfulness: command prose, SKILL.md, CLAUDE.md and README describe the same session arc **ending in the `/goal /monitor ok` hand-off**; the closing prose never recommends `/drive`; no reference to the retired `summary` mode reappears.
- The reconciliation line's derivation (readers, not assertion) is stated in the command prose and covered by a sentinel in the test suite's prose checks if monitor-style sentinels are extended to the mission command.

## Considerations

- A deferred mission stays deferred for the session only — the next `/mission` run surfaces it again (no cross-session deferral memory; that concern is tracked separately for `/monitor`).
- This session is the daytime-planning half of the overnight model: `/mission` makes everything drive-ready, `/monitor` executes it unattended.
