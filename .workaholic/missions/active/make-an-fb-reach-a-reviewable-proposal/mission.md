---
type: Mission
title: Make an FB reach a reviewable proposal
slug: make-an-fb-reach-a-reviewable-proposal
status: active
merge_policy:
created_at: 2026-08-04T10:36:07+00:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260803125843-make-workaholify-a-per-developer-setup-with-event-scoped-routines-and-no-fixed-channel-convention.md, 20260803131441-restructure-workaholifys-fb-issue-template-into-motivation-proposal-notes-sections-with-mission-ticket-breakdown-and-a-propose-title-prefix.md, 20260804085719-make-the-web-routine-notify-slack-only-and-filter-what-it-posts.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Make an FB reach a reviewable proposal

## Goal

An FB stops at a feedback record. The step that turns it into reviewable work —
a mission with its ticket set — never runs: `/workaholify` ships no `propose`
routine, and `/propose`'s cursor bootstraps to `origin/main` HEAD, so a fresh
container reads every merged record as already-seen. C1 assumed a long-lived
server; web routines are ephemeral.

## Experience

A developer files an FB and receives, without asking again, either a proposal
pull request carrying a mission and its tickets, or a stated reason none was
warranted. "Not proposable" is distinguishable from "never processed".

## Acceptance

- [ ] A proposal step runs unattended against this repository on its own, with
      no local state carried between runs (#20260804103637-ship-a-propose-routine-so-planning-runs-at-all.md)
- [ ] An FB raised in Slack produces either a proposal PR or a recorded reason
      it did not, visible without opening a session log (#20260804103637-report-a-proposal-verdict-back-to-its-fb.md)
- [ ] The feedback merged before a runner's container existed is still
      proposable, proven against a record older than the run (#20260804103637-make-the-proposal-window-survive-a-fresh-container.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
