---
type: Mission
title: Make the workflow scripts survive a GraphQL-restricted gh
slug: make-the-workflow-scripts-survive-a-graphql-restricted-gh
status: active
merge_policy:
created_at: 2026-08-12T17:26:31+00:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours: 1.4
feedback: [20260812172522-workflow-scripts-assume-a-gh-graphql-surface-a-web-session-may-not-serve.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260812-182547
---

# Make the workflow scripts survive a GraphQL-restricted gh

## Goal

Seven scripts across five skills reach GitHub through `gh` subcommands backed by
GraphQL (`gh issue list`, `gh pr list|create|merge|view`). A Claude Code Web session
is not guaranteed to serve that surface: measured 2026-08-12 17:19 UTC, this
repository's own `[Propose]` tick got HTTP 403 "only the pinned set of PR-review
operations is served", while a run 80 minutes earlier used the same paths
successfully. The capability is per-session; the scripts treat it as static. REST
(`gh api repos/{owner}/{repo}/...`) answers in both. Route through REST so a
restricted session degrades instead of stopping — the standing rule for routines
(FB `20260810161811`) and the reason `list-proposed-refs.sh` is already git-native.

## Experience

A routine tick in a GraphQL-restricted session ingests its assigned issues, opens
its pull request and merges it — the same run it would have performed unrestricted.
No step reports `list_failed` or `pr_failed` for a reason the environment can serve.

## Acceptance

- [x] Issue discovery succeeds in a session serving only pinned PR-review operations (#20260812172713-read-the-inbound-issue-inbox-through-rest.md)
- [x] A proposal opened in that same session reaches a merged pull request (#20260812172713-open-and-merge-pull-requests-through-rest.md)
- [ ] The hermetic suite fails if a workflow script regains a hard GraphQL dependency (#20260812172713-cover-the-remaining-gh-readers-and-pin-the-dependency.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-12 — ticket archived — 20260812172713-read-the-inbound-issue-inbox-through-rest.md
- 2026-08-12 — ticket archived — 20260812172713-open-and-merge-pull-requests-through-rest.md
- 2026-08-12 — run recorded (+1.4h) — implement-20260812-180600
