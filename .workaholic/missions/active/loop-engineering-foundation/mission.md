---
type: Mission
title: Loop engineering foundation
slug: loop-engineering-foundation
status: active
created_at: 2026-07-28T18:31:48+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee: a@qmu.jp
strategy: agent-orchestrated-development
drive_authorized: true
predicted_hours: 10
actual_hours:
tickets: []
stories: []
concerns: []
gate_type:
gate_target:
gate_assert:
---

# Loop engineering foundation

## Goal

Phase 1 of the loop-engineering reorganization (decision record: `docs/loop-engineering-workflow.md`, decided 2026-07-28). workaholic is evolving from a per-developer plugin into a team development engine: humans continuously supply **feedback** (design discussions, Slack instructions, discussion conclusions), and the AI turns that stream into proposed missions, discusses them, and implements approved ones unattended. This mission lays the artifact-level foundation that everything later (proposal batch, draft/approval flow, cron worker — phases 2–4) builds on: a first-class `feedbacks/` artifact, mission ownership carried on the mission itself, and the retirement of the strategy layer whose direction-keeping role the feedback stream takes over.

## Scope

Done when: (1) `feedbacks/` exists as a registered, hook-validated, OKF-indexed artifact directory with an internal capture skill and a `/feedback` command usable from any session; (2) a mission's owner(s) are carried on the mission's own `assignees` and read through `mission-owners.sh` by every existing consumer, unchanged; (3) the strategy layer is retired — no strategy resolution at mission creation/replan, validator floor updated, skill removed, existing strategies migrated with their Direction preserved as feedback, allowlist and rules table updated in the same change, docs swept.

Out of scope (later phases of the decision record): the proposal batch and its cursor, mission `status: draft` / `merge_policy` and the approval flip, Slack integration (Claude Tag inbound, bot outbound), the cron implementation worker, kioku transcript ingestion, and any change to `/monitor`'s execution machinery beyond the ownership reader it already uses.

Positioning note: this worktree is cut from `main` @ `41abd793`. The ownership-to-strategy model (2026-07-24) and the decision record ride the unmerged `work-20260724-092537` branch (the decision record itself is cherry-picked here as `docs/loop-engineering-workflow.md`; identical adds merge cleanly). Where this checkout's code disagrees with that branch, the *newer branch* states current doctrine — tickets 2 and 3 land on whatever state `/ship`'s standard catch-up-with-main produces at drive time, and this mission.md carries a legacy `assignee` so its owner resolves under both ownership models.

## Experience

- Any session — a Slack-backed one later, a local one today — registers a feedback: a conformant `type: Feedback` file (a `kind` + `source` pair, author, timestamp slug) lands under `.workaholic/feedbacks/`, the area index refreshes, and `layout-doctor.sh` stays `conforming: true`. Feedback files are immutable records: consumers track "new" by commit cursor, never by mutating them; resolution/mootness is a new `supersedes` entry.
- A hand-edit that violates the feedback floor (wrong location, missing `type`/`source`, bad filename) is blocked at write time by a PostToolUse validator, exactly as tickets and missions are.
- A mission's owners are read from its own `assignees` (plural; creator-seeded at scaffold) through `mission-owners.sh`; the mission lens, bare `/mission`, `/monitor` scope, and `ship`'s concern lane behave exactly as before for owned missions, and a mission with no assignees surfaces as claimable. Claiming a mission is a one-line edit to that mission, not to any other artifact.
- `/mission` creation and replan no longer resolve or interrogate a strategy; `validate-mission.sh`'s authorized floor requires owner + Experience + Acceptance only. Legacy `strategy:` frontmatter on archived missions is tolerated, never retro-blocked.
- After the migration, `.workaholic/strategies/` is gone from the tree, the allowlist, and the rules table — in lockstep — and each retired strategy's `## Direction` prose survives verbatim as a `source: discussion` feedback entry, the first citizens of the new corpus.

## Acceptance

- [x] `feedbacks/` exists as a first-class OKF artifact — one immutable file per feedback with `type: Feedback` frontmatter, an internal `feedback` skill with create/list scripts, a thin `/feedback` command, a PostToolUse validator, area indexing, and same-commit allowlist + rules registration (#20260728183201-add-feedback-artifact-and-capture-skill.md)
- [x] Mission ownership is carried on the mission's own plural `assignees` (creator-seeded), read through `mission-owners.sh` ahead of any strategy fallback, with every consumer behaviorally unchanged (#20260728183202-carry-mission-ownership-on-assignees.md)
- [x] The strategy layer is retired: no strategy step at mission creation/replan, validator floor updated, strategy skill removed, live strategies migrated (Direction preserved as feedback, assignees folded down), allowlist + rules updated in the same commit, docs swept (#20260728183203-retire-strategy-layer.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-07-28 — mission created — mission.md
- 2026-07-28 — strategy linked — agent-orchestrated-development — mission.md
- 2026-07-28 — duration predicted (hand estimate 10h, archive basis 0) — mission.md
- 2026-07-28 — ticket added — 20260728183201-add-feedback-artifact-and-capture-skill.md
- 2026-07-28 — ticket added — 20260728183202-carry-mission-ownership-on-assignees.md
- 2026-07-28 — ticket added — 20260728183203-retire-strategy-layer.md
- 2026-07-28 — mission replanned (feedback kind axis; concern merger recorded ahead) — mission.md
- 2026-07-28 — ticket archived — 20260728183201-add-feedback-artifact-and-capture-skill.md
- 2026-07-28 — ticket archived — 20260728183202-carry-mission-ownership-on-assignees.md
- 2026-07-28 — ticket archived — 20260728183203-retire-strategy-layer.md
