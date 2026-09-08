---
type: Mission
title: Make Slack intake honor its declared binding and complete thread coverage
slug: make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage
status: achieved
merge_policy:
created_at: 2026-09-08T14:24:25+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260908123559-discover-new-human-replies-inside-existing-slack-threads.md, 20260908123606-honor-repository-declared-qfs-slack-bindings-before-connector-fallback.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260908-175301
---

# Make Slack intake honor its declared binding and complete thread coverage

## Goal

Make the repository's declared Slack destination and speaking identity the startup authority for
the development loop, then prove that the selected route can discover and handle new human thread
replies before the loop claims its inbound coverage is complete.

## Experience

A repository operator can name the Slack workspace, channel, preferred QFS profile and sender once.
Every loop turn validates that binding, sees a new reply even when it is buried in an existing
private thread, and names the exact degradation before using the same destination through a fallback.

## Acceptance

- [x] Repository instructions carry one portable Slack binding that `/workaholify` can scaffold and audit. (#20260908142454-declare-and-audit-the-repository-slack-binding.md)
- [x] Startup resolves one verified QFS account, destination and sender, and discovers new thread replies with bounded overlap before classification. (#20260908142454-discover-and-classify-new-replies-before-claiming-thread-coverage.md)
- [x] Every fallback and revalidation preserves the bound channel/thread and reports the typed QFS or identity failure that caused it. (#20260908142454-preserve-typed-fallback-and-revalidate-slack-effects.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-08 — ticket archived — 20260908142454-declare-and-audit-the-repository-slack-binding.md
- 2026-09-08 — ticket archived — 20260908142454-resolve-and-validate-the-preferred-qfs-slack-route.md
- 2026-09-08 — ticket archived — 20260908142454-discover-and-classify-new-replies-before-claiming-thread-coverage.md
- 2026-09-08 — ticket archived — 20260908142454-preserve-typed-fallback-and-revalidate-slack-effects.md
- 2026-09-08 — mission achieved — mission.md
