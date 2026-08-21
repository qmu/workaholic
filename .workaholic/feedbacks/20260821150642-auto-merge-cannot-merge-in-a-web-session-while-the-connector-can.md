---
type: Feedback
title: Auto-merge cannot merge in a web session while the connector can
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-08-21T15:06:42+09:00
author: a@qmu.jp
supersedes: 
---

# Auto-merge cannot merge in a web session while the connector can

# Auto-merge cannot merge in a web session (REST 403) while the connector can

Source: https://github.com/qmu/workaholic/issues/544

`publish-tree-pr.sh`'s `WORKAHOLIC_AUTO_MERGE=1` merges through `gh-rest.sh api repos/<slug>/pulls/<n>/merge --method PUT`. Measured 2026-08-20 on an hourly tick, that call returns **403** in a Claude Code on the web session:

    {"message":"Merging pull requests is not permitted for this session type.",
     "documentation_url":"https://docs.anthropic.com/en/docs/claude-code/github-actions"}

403 is neither 405 nor 409, so the reason falls through to `merge_reason: merge_failed` — the unknown-failure bucket. The GitHub MCP `merge_pull_request` tool merged the same pull request with 200 immediately after.

Every `[Specificate]` proposal pull request opened from a remote session therefore stays open, so the 2026-08-11 design — "`main` is the continuously auto-merged development branch" — does not hold in that execution class; and because the report says only `merge_failed`, a reader looks for a defect in their own change.

Two things are asked for: in a remote session, merge through the connector rather than REST; and failing that, at minimum report the 403 as its **own named reason** so the reader does not mistake it for a fault of their own.

The reporter notes that `rules/shell.md`'s "GitHub over REST only" rule is about `gh issue|pr|repo` being GraphQL-backed and 403-ing in web sessions, and that this is the mirror case: a REST endpoint a web session also refuses. Whether a connector tool may become a sanctioned transport for a workflow script — a script cannot call an MCP tool, only an agent can — is named as the design question, and as exactly the fork that makes the named-reason fallback worth shipping either way. The distinguishable signal is the status code plus the message string, both already in the response.
