---
type: Mission
title: Loop engineering proposal loop
slug: loop-engineering-proposal-loop
status: achieved
created_at: 2026-07-28T21:03:01+09:00
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

# Loop engineering proposal loop

## Goal

Phase 2 of the loop-engineering reorganization (decision record: `docs/loop-engineering-workflow.md`; phase 1 shipped as v1.0.105). With the feedback stream live, this mission makes it *productive*: the concern corpus merges into the stream (decision H2 — one unified inbound record, `kind: concern`, with resolution as `supersedes` records at the carry-over seams per H3), and a **proposal batch** starts reading the stream — detecting feedback newly merged to main by commit cursor, judging whether a mission is warranted, registering **draft** missions with `feedback:` traceability, and notifying Slack through the bot channel (E2). This is the "AI proposes, humans approve" half of the vision; the approval flip and the unified `/drive` executor are phase 3.

## Scope

Done when: (1) the concern corpus is merged into the feedback stream — `ship`'s extraction writes `kind: concern` feedback records, `/report` resolves open concerns by writing superseding records, the concern lifecycle machinery (triage/merge/re-grade/demote) is retired, the existing corpus is migrated, and `concerns/` is removed from tree/allowlist/rules in lockstep; (2) a headless `/propose` command exists — cursor over main, new-feedback reading, draft-mission scaffolding (`status: draft`, unowned, `feedback:` refs), dedup against existing missions, commit + push, with silence a valid outcome; (3) a Slack notifier (env-driven bot post, graceful no-op without a token) is wired into `/propose` and the 15-minute cron runbook is documented.

Out of scope (phase 3+ of the decision record): the approval flip (`draft → approved`) and the `status` unification retiring `drive_authorized` (I2); per-artifact `merge_policy` (G5); the unified `/drive` with claim protocol and the retirement of `/monitor`/`/trip`/`/carry` (G1–G3, I1, I5); Claude Code Web porting and kioku ingestion (phase 4). Replan proposals for existing missions (C3 second stage) are also out — this batch proposes new missions only.

Positioning note: legacy `assignee`/`strategy` keys are carried in this frontmatter solely so the mission validates under a pre-v1.0.105 installed plugin's hooks; the current code tolerates and ignores both.

## Experience

- A shipped story's section-6 concerns land in `.workaholic/feedbacks/` as `kind: concern` records (severity kept as a producer field, mission/ticket relations preserved); when a later branch fixes one, `/report` writes a **superseding** record naming it — no status flip, no archive move, and the open set is simply "concern records nobody superseded".
- The old lifecycle machinery is gone: no triage prompt, no demote/merge/re-grade scripts, no `(carried from PR #N)` prepending — a story's section 6 records **this branch's** concerns only, and curation is the reader's judgment over the stream.
- Running `/propose` headlessly (cron or by hand) reads feedback merged to main since the last cursor, and either does nothing (silence is valid, cursor advances) or registers one or more **draft** missions — `status: draft`, unowned, `feedback: [<record filenames>]` — committed and pushed to main, each announced to Slack as the bot when a token is configured (a missing token is a recorded no-op, never a failure).
- The same feedback never spawns two proposals: the cursor bounds what is read, and the drafter checks existing missions' `feedback:` refs before writing.
- A developer can read the cron runbook and wire the 15-minute loop on any server with headless claude and a bot token in under ten minutes.

## Acceptance

- [x] The concern corpus is merged into the feedback stream: ship-time extraction writes `kind: concern` records, `/report` resolves by superseding record, the triage/demote/merge/re-grade machinery is retired, the live corpus is migrated, and `concerns/` is removed from allowlist + rules in the same commit (#20260728210301-merge-concern-corpus-into-feedback-stream.md)
- [x] A headless `/propose` command and internal `propose` skill exist: commit-cursor detection over main, new-feedback reading, draft-mission scaffolding with `feedback:` refs and dedup, commit + push, silence valid (#20260728210302-add-proposal-batch-command-and-skill.md)
- [x] A Slack bot notifier (env-driven, graceful no-op) is wired into `/propose` and the 15-minute cron runbook is documented (#20260728210303-add-slack-notifier-and-proposal-runbook.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-07-28 — mission created — mission.md
- 2026-07-28 — duration predicted (hand estimate 10h, archive basis 0) — mission.md
- 2026-07-28 — ticket added — 20260728210301-merge-concern-corpus-into-feedback-stream.md
- 2026-07-28 — ticket added — 20260728210302-add-proposal-batch-command-and-skill.md
- 2026-07-28 — ticket added — 20260728210303-add-slack-notifier-and-proposal-runbook.md
- 2026-07-28 — ticket archived — 20260728210301-merge-concern-corpus-into-feedback-stream.md
- 2026-07-28 — ticket archived — 20260728210302-add-proposal-batch-command-and-skill.md
- 2026-07-28 — ticket archived — 20260728210303-add-slack-notifier-and-proposal-runbook.md
- 2026-07-28 — story reported — work-20260728-210259.md
- 2026-07-28 — concern deferred (stuck) — 20260728215635-the-proposal-judgment-bar-is-unproven.md
- 2026-07-28 — concern deferred (stuck) — 20260728215635-the-feedback-stream-has-no-reader.md
- 2026-07-28 — concern deferred (stuck) — 20260728215635-draft-acceptance-sketches-could-be-mistaken.md
- 2026-07-28 — mission achieved — mission.md
- 2026-07-29 — concern resolved (unstuck) — 20260728215635-draft-acceptance-sketches-could-be-mistaken.md
