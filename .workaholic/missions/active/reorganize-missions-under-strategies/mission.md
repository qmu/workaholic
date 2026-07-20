---
type: Mission
title: Reorganize missions under strategies
slug: reorganize-missions-under-strategies
status: active
created_at: 2026-07-21T02:57:09+09:00
author: a@qmu.jp
assignee: a@qmu.jp
strategy: agent-orchestrated-development
drive_authorized: true
predicted_hours: 8
actual_hours:
tickets: []
stories: []
concerns: []
gate_type:
gate_target:
gate_assert:
---

# Reorganize missions under strategies

## Goal

Shift workaholic's planning hierarchy to an after-hours agent-orchestration model: during the day the developer spends their time on **mission planning** (front-loading every judgment call an agent would otherwise ask); after hours, coding agents execute those missions in parallel, long-running and unattended, so the morning starts with reviewable results. Today the mission plays two roles at once — the executable unit *and* the long-lived goal container. This mission splits them: a new **strategy** artifact takes over the long-lived, no-end-condition direction role, and the mission narrows to the **overnight-executable execution plan of a strategy** — a fairly immediate developer request, interrogated to question-free drive-readiness for *any* coding agent, not just Claude Code. Around that split, three feedback loops make the system compound: orchestration throughput becomes measurable (commit count over size-normalized commits — a KPI of how well the agent fleet is orchestrated, not of human performance), duration predictions become data-driven (archived predicted-vs-actual records), and each night's run writes a recorded reflection that sharpens the next day's planning toward fully question-free autonomy.

## Scope

Done when: (1) strategy exists as a first-class artifact + internal skill and every newly authorized mission links to one (developer-confirmed or agent-inferred, created on the spot when none fits); (2) missions record predicted and actual agent-hours, with the prediction derived from archived-mission trends; (3) `/monitor`'s final report states per-mission completed-as-planned/reasons, appends a per-mission reflection, and auto-creates the PR for each genuinely complete mission (merge stays `/ship`); (4) the commit-count KPI is computable by a deterministic script and surfaced in `/catch`, with the per-commit size gate landed in release-scan; (5) the commit → ticket → mission → strategy granularity discipline and the redefinition are documented.

Out of scope: auto-merge to main (merge remains `/ship`'s deploy-evidence-gated step — ruled at creation); `/goal` itself (a Claude Code harness feature, not a workaholic command); reshaping git history to improve KPI numbers (no squash/grooming — `development/commit-change-history`); editing the qmu.co.jp policy hard copies under `skills/<pillar>/policies/`; retrofitting strategy links onto already-archived missions.

Positioning note: this worktree is cut from `main` @ `e22fe89a`; the `work-20260719-075112` batch (monitor front-loading, reorganize-and-carry doctrine, interaction rule) is not yet on main. Where this checkout's docs disagree with that branch, the *newer branch* states current doctrine — reconcile at drive time where files overlap, and rely on `/ship`'s standard catch-up-with-main before merge.

## Experience

- `/mission "<request>"` checks existing tickets and source first, then asks **only the questions no option can be honestly recommended for** — everything recommendable is decided and recorded, not asked — informed by past missions' reflections; it resolves the mission's **strategy** link (inferring and proposing from existing strategies, creating one when none fits), predicts duration from archived-mission trends, and emits a complete, ordered, drive-ready ticket set in `.worktrees/<slug>/` where **no later executor — Claude Code or any other coding agent — needs to ask anything**.
- `/monitor` (looped by `/goal`) drives every authorized mission in its own worktree in parallel; by morning each genuinely complete mission has an **open PR**, the final report states which missions completed as planned and the concrete reasons the rest did not, and every driven `mission.md` carries a dated `## Reflection` entry naming what blocked (or would have blocked) autonomy and what the next planning should front-load.
- `/mission close` archives the mission with `predicted_hours` and accumulated `actual_hours` recorded; the next `/mission` creation's prediction reads those archived records.
- `/catch` shows orchestration throughput: agent-authored commit counts over the window, meaningful because per-commit size is normalized by the release-scan changed-lines gate.
- A strategy document answers "why are these missions being launched"; a mission answers "what does this batch of tickets accomplish tonight"; a ticket answers "what is this one change"; no artifact restates a lower level's detail.

## Acceptance

- [x] A strategy artifact (`type: Strategy`, active/archive areas, create/list/reader scripts, OKF-indexed) exists as an internal skill (#20260721025715-add-strategy-artifact-and-skill.md)
- [x] Mission creation/replan resolves a strategy link (propose-or-create, decide-and-record) and `validate-mission.sh` enforces it at the `drive_authorized` floor; this mission itself is linked as the live demo (#20260721025716-link-missions-to-strategies-at-creation.md)
- [x] Missions record `predicted_hours`/`actual_hours`; prediction derives deterministically from archived-mission trends; `/monitor` accumulates leaf agent-time idempotently (#20260721025717-record-predicted-and-actual-mission-duration.md)
- [x] `/monitor`'s final report states per-mission completed-as-planned/reasons and appends a dated `## Reflection` entry that the next mission planning reads back (#20260721025718-add-monitor-completion-report-and-reflection.md)
- [x] `/monitor` auto-creates the PR for each genuinely complete mission; merge stays `/ship`; terminal-token semantics stay honest (#20260721025719-auto-create-pr-for-completed-missions.md)
- [ ] The commit-count KPI is computable by a deterministic script and surfaced in `/catch` (#20260721025720-add-commit-count-kpi-script-and-catch-surface.md)
- [x] release-scan gains the per-commit changed-lines gate with the generated/bulk exemption (#20260721020759-add-per-commit-changed-lines-gate.md)
- [ ] The commit → ticket → mission → strategy granularity discipline and the mission/strategy redefinition are documented across the skills and repo docs (#20260721025721-document-granularity-discipline-across-artifacts.md)
- [ ] The interrogation protocols ask only unrecommendable questions — anything with a recommendable option is decided and recorded in the artifact instead of asked (#20260721025722-raise-ask-bar-decide-and-record.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-07-21 — ticket added — 20260721020759-add-per-commit-changed-lines-gate.md
- 2026-07-21 — duration predicted (hand estimate 8h, archive basis 0) — mission.md
- 2026-07-21 — ticket archived — 20260721020759-add-per-commit-changed-lines-gate.md
- 2026-07-21 — ticket archived — 20260721025715-add-strategy-artifact-and-skill.md
- 2026-07-21 — strategy linked — agent-orchestrated-development — mission.md
- 2026-07-21 — ticket archived — 20260721025716-link-missions-to-strategies-at-creation.md
- 2026-07-21 — ticket archived — 20260721025717-record-predicted-and-actual-mission-duration.md
- 2026-07-21 — ticket archived — 20260721025718-add-monitor-completion-report-and-reflection.md
- 2026-07-21 — ticket archived — 20260721025719-auto-create-pr-for-completed-missions.md
