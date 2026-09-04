---
type: Mission
title: Make the Codex work entrypoint self-contained
slug: make-the-codex-work-entrypoint-self-contained
status: achieved
merge_policy:
created_at: 2026-09-04T17:16:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.4
feedback: [20260904171517-make-the-codex-work-entrypoint-self-contained-and-diagnostic.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260904-173127
---

# Make the Codex work entrypoint self-contained

## Goal

Make the documented Codex CLI `/work` start path usable from a supported plugin installation,
with precise diagnostics for the clock wrapper and its plugin prerequisites.

## Experience

An operator installs Workaholic into an otherwise empty consuming repository and can launch a
dry-run Codex tick through the documented entrypoint. If the clock wrapper, skill, or command body
is absent, the entrypoint names the missing layer and recommends repair only for that layer.

## Acceptance

- [x] The supported plugin package provides one stable launcher for the external Codex clock. (#20260904171658-package-a-stable-codex-clock-launcher.md)
- [x] Startup diagnoses clock_wrapper_missing separately from missing plugin artifacts. (#20260904171658-diagnose-codex-clock-and-plugin-layers.md)
- [x] An empty consuming-repository fixture installs the package and launches one dry-run tick. (#20260904171658-drill-the-installed-codex-start-path.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-04 — ticket archived — 20260904171658-package-a-stable-codex-clock-launcher.md
- 2026-09-04 — ticket archived — 20260904171658-diagnose-codex-clock-and-plugin-layers.md
- 2026-09-04 — ticket archived — 20260904171658-drill-the-installed-codex-start-path.md
- 2026-09-04 — mission achieved — mission.md
- 2026-09-04 — story reported — work-20260904-173127.md
- 2026-09-04 — run recorded (+0.4h) — 20260904-082601
