---
type: Mission
title: Loop engineering unified drive
slug: loop-engineering-unified-drive
status: approved
created_at: 2026-07-28T22:17:19+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee: a@qmu.jp
predicted_hours: 16
actual_hours:
tickets: []
stories: []
concerns: []
gate_type:
gate_target:
gate_assert:
---

# Loop engineering unified drive

## Goal

Phase 3 of the loop-engineering reorganization (decision record: `docs/loop-engineering-workflow.md`; phases 1–2 shipped as v1.0.105/v1.0.106). The execution side collapses to **one executor**: `/drive` autonomously partitions all approved missions and backlog tickets into PR-worthy units, coordinates concurrent runners through **pushed claim branches** (the repository as the coordination medium), drives each unit in a claim-born worktree through to the report, and — per the artifacts' recorded **merge policy** — ships automatically or stops at a PR announced to Slack. Around it, the state model unifies (`status: draft → approved → …`, retiring `drive_authorized`), the approval flip becomes executable, and the superseded executors (`/monitor`, `/trip`, `/carry`) retire with their machinery. This makes the "Drive Every 5 Minutes" routine (G4) a cron entry over one command.

## Scope

Done when: (1) the mission lifecycle is the single `status` axis — `draft | approved | achieved | abandoned | carried` — with `drive_authorized` retired into `approved` via a living migration, an executable approval flip (draft → interrogated → approved), and per-artifact `merge_policy` recorded at creation/approval (G5, I2); (2) the claim protocol exists as scripts — claim writer (worktree + claim stamp + commit + push), claim reader (unmerged-remote-branch scan), stale-claim reporting — with the claim-born/ship-torn worktree lifecycle (G3, I6); (3) `/drive` is the unified executor — autonomous PR-unit partitioning over approved missions + backlog tickets, per-unit claim → drive → report, effective-merge-policy routing (all-auto → automated `/ship`; otherwise PR + Slack notification), agent-hours recording absorbed, headless-compatible, with the 5-minute routine documented (G1–G2, G4–G5, I7); (4) `/monitor`, `/trip`, and `/carry` are retired — commands, skills, agents, and the reflection channel — with the docs and tests swept (I1, I3, I5).

Out of scope: phase 4 (Claude Code Web port, kioku ingestion, multi-repo rollout); `/goal` removal (**rejected** — I4: `/goal` compatibility and the honest terminal stay); replan proposals from feedback (C3 second stage); multi-runner *proposal* batches (the claim protocol coordinates *drives*; the proposal cursor stays single-runner).

## Experience

- A mission is `draft` until a human approves it; approval is an executable flow (`/mission approve <slug>` or a replan ending in approval) that interrogates to drive-ready, records `merge_policy` (the one genuinely human ruling: `auto` or `review`), and flips `status: approved` — no `drive_authorized` stamp exists on new missions, and legacy stamps migrate on the next script touch, with every executor/validator/lens reading the one status axis.
- Running `/drive` — interactively or from the 5-minute cron — never asks "which work": it fetches, reads the claims already in flight from unmerged remote branches, partitions the unclaimed remainder (each approved mission = one unit; related backlog tickets = one batched unit sharing a PR), claims each unit on a fresh pushed branch, and drives. Two runners on two machines never double-pick the same unit.
- A unit's worktree is born at claim and torn down when its PR merges; an unfinished unit is simply re-claimed by a later tick from the pushed branch.
- A unit whose members are all `merge_policy: auto` goes through the automated `/ship` doctrine (deploy + verify evidence **before** merge; secrets still hard-block); any `review` member — or auto work depending on review work — stops at the PR, whose URL is posted to Slack via the existing notifier.
- `/monitor`, `/trip`, and `/carry` no longer exist: their surviving ideas live in `/drive` (worktrees, honest reporting, PR auto-creation, agent-hours) and the feedback stream (carry-over learnings per H3); `trips/` remains on disk as read-only history.

## Acceptance

- [x] The mission lifecycle is one `status` axis with an executable approval flip and per-artifact `merge_policy`; `drive_authorized` is retired via living migration and every reader keys on status (#20260728221801-unify-mission-status-and-merge-policy.md)
- [x] The claim protocol scripts exist and are hermetically tested: claim writer, unmerged-branch claim reader, stale-claim reporting, claim-born worktree lifecycle (#20260728221802-add-claim-protocol-scripts.md)
- [ ] `/drive` is the unified executor: autonomous PR-unit partitioning, per-unit claim → drive → report, merge-policy routing with automated `/ship` for all-auto units and PR + Slack for the rest, agent-hours absorbed, 5-minute routine documented (#20260728221803-unify-drive-executor.md)
- [ ] `/monitor`, `/trip`, `/carry`, the Agent Teams members, and the reflection channel are retired with docs and tests swept (#20260728221804-retire-monitor-trip-carry.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-07-28 — mission created — mission.md
- 2026-07-28 — duration predicted (hand estimate 16h, archive basis 0) — mission.md
- 2026-07-28 — ticket added — 20260728221801-unify-mission-status-and-merge-policy.md
- 2026-07-28 — ticket added — 20260728221802-add-claim-protocol-scripts.md
- 2026-07-28 — ticket added — 20260728221803-unify-drive-executor.md
- 2026-07-28 — ticket added — 20260728221804-retire-monitor-trip-carry.md
- 2026-07-29 — ticket archived — 20260728221801-unify-mission-status-and-merge-policy.md
- 2026-07-29 — ticket archived — 20260728221802-add-claim-protocol-scripts.md
