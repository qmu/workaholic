---
created_at: 2026-07-18T18:54:10+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain, Config]
effort: 2h
commit_hash:
category: Added
depends_on:
mission:
---

# Add /monitor — parallel mission driver command and skill

## Overview

Add a new Claude-Code-only command `/monitor` (plus a comprehensive `workaholic:monitor` skill) that integrally runs the current developer's **assigned active missions in parallel**: one autonomous drive per mission, each executing inside that mission's dedicated `.worktrees/<slug>/` worktree, until every mission's completion conditions are met or only items blocked on ignored developer escalations remain. At that terminal state `/monitor` emits a deterministic `ok`, so a caller-side loop such as `/goal /monitor ok` (see Considerations — `/goal` is an external convention, not part of this ticket) can clear.

The run opens with a **pre-flight review confirmed with the developer** before anything is driven:

1. The assigned active missions (via `mission/scripts/summary.sh` — assignee == me first, then **unassigned offered as claimable**; claiming one at pre-flight assigns it to the current developer and includes it in the run).
2. Each mission's current position: derived progress (`checked/total`), next unchecked acceptance item, and **unmerged in-flight work** (the `catch` Missions-view split of merged `window_events` vs unmerged `in_flight`).
3. Unattended-drive eligibility: which missions pass `mission/scripts/drive-authorized.sh` (stamped `drive_authorized: true` **and** non-empty `## Acceptance`). Ineligible missions are **not driven** — they are surfaced here and routed to `/mission` replan.
4. Anticipated cross-mission interference (shared files/paths across the missions' ticket sets) and where this run intends to take each mission.

After confirmation, the command fans out **one `general-purpose` leaf per eligible mission** (single message, parallel Task calls). Each leaf preloads `workaholic:drive` and drains that mission's queue in the mission-authorized/night shape — prioritization done inline (drive's Agent Compatibility note), no per-ticket prompt, no AskUserQuestion, no nested Task — with every bash call wrapped `( cd <worktree_path> && … )`. Each leaf returns drive Night Mode's closed three-outcome report (`implemented`/`failed`/`blocked` + `deferred`) plus any escalations. The main agent collects the reports, resolves cross-mission conflicts from the bird's-eye vantage, and loops (re-driving missions with remaining, newly-unblocked work) until the terminal state, then presents the final bird's-eye report — always including the list of escalations left for the developer. Pull requests during missions follow `/report` and `/ship` unchanged.

`/monitor` is Claude-Code-only orchestration, like `/trip`: its script-bearing skill carries `metadata.internal: true`, it is **not** added to `build.mjs` `DEFAULT_TARGETS` (no `outputs/` footprint), and the command carries the `workaholic:policy-lens` sentinel.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work)
- `workaholic:development` / `policies/overnight-ai.md` — the policy `/monitor` operationalizes: judgment pre-answered at pre-flight, no mid-run stops, remaining judgment calls collected for post-run review
- `workaholic:development` / `policies/weekly-quota.md` — parallel autonomous mission runs are the sanctioned destination for open quota; anchors the `/goal /monitor ok` usage pattern
- `workaholic:development` / `policies/qa-engineering.md` — the developer owns QA: the escalation list in the final report is the seam where the developer reviews what the unattended run produced; the design must guarantee that seam exists
- `workaholic:planning` / `policies/ai-native-future.md` — AI-driven processes stay observable and interruptible: the pre-flight confirmation and the bird's-eye view are the human-in-the-loop path; the developer can interrupt and take over (`monitor → interrupt → /drive` mirrors `trip → interrupt → /drive`)
- `workaholic:design` / `policies/modeless-design.md` — the pre-flight is the one warranted confirmation; after it, operation stays interruptible rather than trapping the developer in a mode
- `workaholic:implementation` / `policies/observability.md` — an unattended run must be explainable from outside: the bird's-eye report (missions, progress, remaining, interference, escalations) is the observation output

## Key Files

- `plugins/workaholic/commands/monitor.md` — NEW thin command (~50-100 lines): pre-flight orchestration, labeled AskUserQuestion, parallel leaf fan-out, loop + synthesis; model on `commands/mission.md` (worktree subshell idiom, labeled prompts) and `commands/trip.md` (Claude-only parallel orchestration, context-aware entry)
- `plugins/workaholic/skills/monitor/SKILL.md` — NEW comprehensive skill (`metadata.internal: true`): pre-flight assembly, eligibility gating, per-leaf prompt template, interference analysis, loop/terminal conditions, final-report schema
- `plugins/workaholic/skills/monitor/scripts/` — NEW POSIX scripts (e.g. `preflight.sh` assembling mission set + worktree map + eligibility, `terminal.sh` deciding completion/escalation-remainder) — reuse mission scripts, never re-derive
- `plugins/workaholic/skills/mission/scripts/summary.sh` — the exact assignee scope (mine first, then unassigned-claimable); use verbatim
- `plugins/workaholic/skills/mission/scripts/drive-authorized.sh` — unattended-drive eligibility gate per mission
- `plugins/workaholic/skills/mission/scripts/{progress,next-acceptance,gate,list,read-relation,slug}.sh` — completion conditions (`checked==total`, plus `gate.sh` when a `gate_*` is set) and derivations; never hand-edit mission state
- `plugins/workaholic/skills/drive/SKILL.md` — Night Mode §1–§5: the autonomous contract each leaf inherits (batch authorization, attempt-first, closed three-outcome report); Agent Compatibility note (inline prioritization in a leaf)
- `plugins/workaholic/skills/drive/scripts/{list-todo,archive}.sh` — per-worktree queue + the seam that already rolls mission changelog/acceptance/OKF per archived ticket
- `plugins/workaholic/skills/branching/scripts/{list-all-worktrees,create-mission-worktree}.sh` — mission slug → `worktree_path` map; materialize a missing worktree for a carried/thin mission (pre-flight detects and reports)
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — merged `window_events` vs unmerged `in_flight` per mission; the pre-flight "current position including unmerged work"
- `plugins/workaholic/skills/gather/scripts/{project-label,git-context}.sh` — `[<project label>]` prompt prefix (required by `guard-askuserquestion-label.sh`) and git context
- `scripts/build-plugins/build.mjs` — confirm `DEFAULT_TARGETS` is deliberately **not** extended (monitor has no `outputs/` footprint)
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests for the new monitor scripts
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` — Commands table + docs updated in the same change

## Related History

Nearly every mechanism `/monitor` composes already exists: unattended autonomous drive (Night Drive/Night Trip), the mission model with per-mission worktrees and mission-authorized gate-skip, the continuous drive loop, and the Mission Position Report. `/monitor` is a new orchestration layer over these, constrained by the one-level fan-out rule.

Past tickets that touched similar areas:

- [20260617010324-add-night-drive-mode.md](.workaholic/tickets/archive/work-20260617-000311/20260617010324-add-night-drive-mode.md) - Autonomous no-per-ticket-approval drive ("invocation is the authorization"; morning report)
- [20260701221803-night-drive-attempt-every-ticket.md](.workaholic/tickets/archive/work-20260701-221800/20260701221803-night-drive-attempt-every-ticket.md) - Attempt-first contract and the closed set of legitimate stop reasons
- [20260622220702-add-night-trip-autonomous-mode.md](.workaholic/tickets/archive/work-20260621-192132/20260622220702-add-night-trip-autonomous-mode.md) - Parallel multi-agent autonomous mode precedent
- [20260716012847-mission-interrogation-emits-ticket-set.md](.workaholic/tickets/archive/work-20260715-213222/20260716012847-mission-interrogation-emits-ticket-set.md) - A mission owns a complete drive-ready ticket set + dedicated worktree — what /monitor drives
- [20260716103000-mission-quality-gate-design.md](.workaholic/tickets/archive/work-20260716-152211/20260716103000-mission-quality-gate-design.md) - Mission completion conditions (Acceptance + gate) and known gate/worktree defects the leaves will meet
- [20260716102952-mission-position-is-always-reported.md](.workaholic/tickets/archive/work-20260715-213222/20260716102952-mission-position-is-always-reported.md) - Mission Position Report = the per-mission content of the pre-flight and the bird's-eye view
- [20260716163006-worktree-and-trip-association-gaps.md](.workaholic/tickets/archive/work-20260716-152211/20260716163006-worktree-and-trip-association-gaps.md) - Worktree-handling gaps directly in the execution surface
- [20260202192408-continuous-drive-loop.md](.workaholic/tickets/archive/drive-20260202-134332/20260202192408-continuous-drive-loop.md) - The intra-mission loop /monitor wraps across missions
- [20260408113052-fix-abandon-stops-session.md](.workaholic/tickets/archive/work-20260408-001129/20260408113052-fix-abandon-stops-session.md) - Stop/escalation discipline the terminal state generalizes
- [20260526011416-route-drive-and-ticket-orchestration-through-general-purpose-subagents.md](.workaholic/tickets/archive/work-20260518-235327/20260526011416-route-drive-and-ticket-orchestration-through-general-purpose-subagents.md) - The one-level fan-out rules that shape the whole design

## Implementation Steps

1. Write `skills/monitor/SKILL.md` (comprehensive, `metadata.internal: true`, `skills:` preloads for mission/drive/catch/branching/gather): pre-flight assembly, eligibility rule (only `drive-authorized.sh`-passing missions run unattended; ineligible → surface + route to `/mission` replan; missing worktree → report, offer `create-mission-worktree.sh`), unassigned-claimable semantics, per-leaf prompt template (preload `workaholic:drive`, mission-authorized/night shape, inline prioritization, `( cd <worktree_path> && … )` for every bash call, return Night-Mode closed report + escalations), loop/terminal definition (per mission: `progress.sh` `checked==total` plus `gate.sh` when set; run: all missions complete OR only ignored-escalation blockers remain → emit `ok`), bird's-eye final-report schema (always lists remaining escalations), interference-analysis guidance (main-agent advisory synthesis over the missions' ticket key-files).
2. Add POSIX `#!/bin/sh -eu` scripts under `skills/monitor/scripts/` for every conditional/multi-step operation (pre-flight data assembly joining `summary.sh` × `list-all-worktrees.sh` × `drive-authorized.sh`; terminal-state evaluation), reusing mission/branching/catch scripts via `${CLAUDE_PLUGIN_ROOT}` — no inline git, no re-derived assignee logic, no stored progress.
3. Write `commands/monitor.md` (thin): policy-lens sentinel comment, Plugin-boundary Notice, check-deps pre-check, pre-flight via the skill's scripts, one labeled AskUserQuestion for the pre-flight confirmation (body prefixed with `[<project label>]`; claimable unassigned missions offered `multiSelect`), parallel leaf fan-out in one message, collect/loop/synthesize, final report + deterministic `ok` terminal output. Document the unattended path: when invoked from a caller-side loop, log the pre-flight content instead of blocking on it only if the developer pre-authorized that in the invocation (mirror Night Drive's "invocation is the authorization").
4. Ensure leaf writes stay confined: each leaf's prompt names exactly one `worktree_path`; the command never runs two leaves on one worktree ("data plural, placement singular").
5. Add hermetic smoke tests to `scripts/test-workflow-scripts.mjs` for the new monitor scripts (mission-set assembly incl. unassigned ordering, eligibility gating of unauthorized/empty-Acceptance missions, terminal-state truth table: all-complete / escalation-remainder / still-driveable).
6. Update docs in the same change: `CLAUDE.md` Commands table + an Architecture note (executor family: `/drive` solo, `/trip` team, `/monitor` parallel-missions), `README.md`, `.workaholic/README.md`.
7. Run `node scripts/build-plugins/build.mjs` and `verify.mjs`/`validate-metadata.mjs`; confirm **no** `outputs/` diff (monitor deliberately excluded from `DEFAULT_TARGETS`).
8. Live E2E validation per the Quality Gate: two throwaway test missions, run `/monitor` end-to-end, verify terminal behavior and report reconciliation, then close/remove the test missions via the sanctioned scripts.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Pre-flight detects a mission that is not `drive_authorized` or has an empty `## Acceptance`, does **not** drive it unattended, and routes it to `/mission` replan (visible in both the pre-flight and the final report).
- Every leaf report uses the closed outcome set `implemented`/`failed`/`blocked` (+ `deferred` minting a ticket) and its counts reconcile against that mission's queue size; the final bird's-eye report always lists the remaining escalations.
- Each leaf's writes land only inside its own mission's `.worktrees/<slug>/` — parallel leaves never touch another tree (verified by inspecting `git status` in every worktree after the E2E run).
- `/monitor` emits `ok` only in the terminal state: every driven mission's completion conditions met (`progress.sh` `checked==total`, `gate.sh` pass when set) or only ignored-escalation blockers remain; otherwise it keeps looping or reports why it stopped.
- Unassigned active missions appear in the pre-flight as claimable and are driven only after being claimed (assigned) there; another developer's missions never appear.
- `CLAUDE.md` (Commands table + architecture), `README.md`, `.workaholic/README.md` are updated in this same change.
- `build.mjs` `DEFAULT_TARGETS` unchanged; `outputs/` shows no diff after a full build.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, including new hermetic assertions for the monitor scripts (mission-set assembly, eligibility gating, terminal-state truth table); all new scripts pass `hooks/posix-lint.sh`.
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs` green; `git status` shows no `outputs/` change.
- Live E2E: create two real test missions (each `drive_authorized: true`, small non-empty `## Acceptance`, 1-2 tiny tickets, own worktree), run `/monitor`, observe: pre-flight shows both with position + interference note; parallel leaves drive both; run terminates in the defined terminal state; final report reconciles; worktrees mutually clean.

**Gate** — what must pass before approval:

- The smoke suite, posix-lint, and the build/verify/metadata trio are green; the live two-mission E2E run completed with the acceptance criteria observed; the developer reviews the E2E pre-flight and final bird's-eye report at the `/drive` approval prompt.

## Considerations

- **One-level fan-out is the load-bearing constraint**: a leaf cannot AskUserQuestion or nest Task, so unattended driving is only possible for `drive-authorized.sh`-passing missions, prioritization happens inline in the leaf, and every developer interaction (pre-flight, interference decisions, escalation resolution) is hoisted to the command (`CLAUDE.md` Architecture Policy; `plugins/workaholic/skills/drive/SKILL.md` Agent Compatibility)
- **`/goal` does not exist as a command in this repo** — it is a first-class concept in `development/overnight-ai` and `weekly-quota` policy only. This ticket implements `/monitor` standalone with a deterministic `ok` terminal output so a caller-side `/goal /monitor ok` convention works; implementing `/goal` itself is explicitly out of scope (a future ticket if wanted)
- **Subagent cwd resets between bash calls** — every leaf command must be absolute-path or `( cd <worktree_path> && … )`; `guard-working-directory.sh` only reminds (`plugins/workaholic/hooks/guard-working-directory.sh`)
- **Unbounded-run risk**: "does not stop until completion" + parallel leaves needs Night Mode's bounded-batch discipline per mission and a main-loop iteration cap; ignored escalations must terminate the loop, never spin (`plugins/workaholic/skills/drive/SKILL.md` Night Mode §3/§5)
- **Interference detection is advisory synthesis, not a mechanical gate**: leaves run in isolated worktrees off main and cannot see each other's uncommitted work; conflicts materialize at `/report`/`/ship`. The command compares ticket key-files across missions and sequences/flags, it does not diff trees
- **Port/resource contention** is already mitigated by `create-mission-worktree.sh`'s per-worktree port allocation (`plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh`)
- **Every AskUserQuestion body needs the `[<project label>]` prefix** or `guard-askuserquestion-label.sh` blocks it; note `commands/mission.md` lacks the policy-lens sentinel while drive/catch/trip carry it — `monitor.md` must carry it (`plugins/workaholic/hooks/`)
- **Mission state is never hand-edited**: acceptance ticking/changelog/OKF refresh all happen at drive's `archive.sh` seam inside each worktree; progress is always derived (`plugins/workaholic/skills/mission/scripts/`)
- **PRs unchanged**: each mission's PR flows through `/report` and `/ship` (with its catch-up-main and scan gates); `/monitor` never merges anything itself

## Final Report

Development completed as planned. Live E2E: two throwaway missions (own worktrees, `drive_authorized`, 1 ticket each) driven by two parallel leaves in one wave; both reached `complete: true` (1/1), leaf reports reconciled, worktrees mutually clean, fixtures torn down via `close.sh` + `cleanup-mission-worktree.sh`.

### Discovered Insights

- **Insight**: A mission's `mission.md` is invisible to the main tree until its branch merges, so any main-session mission enumeration must read each mission worktree's own checkout — `summary.sh` alone cannot power a cross-worktree pre-flight.
  **Context**: This is why `preflight.sh` discovers missions in two places (worktree checkouts first, then main-tree missions owning no worktree) and why `status.sh` takes a worktree path, not a slug lookup.
- **Insight**: `validate-ticket.sh` resolves a ticket's `mission:` relation relative to the hook's cwd, so a missioned ticket written into a mission worktree from a main-tree session false-flags as unresolvable (found live during E2E fixture setup; deferred as ticket `20260718191500-validate-ticket-resolves-mission-in-tickets-checkout.md`).
  **Context**: Every `/monitor` leaf that mints a `deferred` ticket inside a worktree crosses this exact seam — the hook fix directly protects the monitor flow.
