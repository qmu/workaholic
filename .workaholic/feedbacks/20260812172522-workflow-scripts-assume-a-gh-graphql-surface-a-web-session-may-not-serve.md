---
type: Feedback
title: Workflow scripts assume a gh GraphQL surface a web session may not serve
kind: instruction
source: discussion
created_at: 2026-08-12T17:25:22+00:00
author: a@qmu.jp
supersedes: 
---

# Workflow scripts assume a gh GraphQL surface a web session may not serve

Measured 2026-08-12 17:19 UTC inside the `[Propose]` routine session itself, and the
developer's ruling on reading it is that this is a workaholic defect, not an
environment quirk to work around: the workflow scripts shell out to `gh`
subcommands whose GraphQL surface a Claude Code Web session is **not guaranteed to
serve**, and they treat that capability as given.

The tick's first step returned
`{"ok": false, "reason": "list_failed", "detail": "HTTP 403: This GraphQL query is
not enabled for this session - only the pinned set of PR-review operations is
served. Use REST via gh api repos/{owner}/{repo}/... instead."}`.
`list-inbound-issues.sh` discovers its asks with `gh issue list`, which is
GraphQL-backed; the session's GitHub proxy answers 403 to everything outside a
pinned PR-review set. REST is unaffected - `gh api user` resolved the identity
(`tamurayoshiya`) in the same run, and `gh api repos/qmu/workaholic/issues?...`
answered normally.

**The correct verdict this hour was a coincidence, not a working mechanism.** The
inbox really was empty (0 open issues, confirmed independently through REST and the
GitHub MCP `list_issues` tool), so `nothing_in_hand` was right - but it was right by
luck. Had an assigned issue been waiting, the tick would have reported `list_failed`
and ingested nothing, every hour, until the session's policy happened to change. The
script's own contract ("an unreadable inbox must never render as an empty one") held
perfectly; what failed is underneath it.

**The blast radius is the whole loop, not the discovery step.** `gh pr list` 403s in
the same session (measured), and the same GraphQL surface backs `gh pr create`,
`gh pr merge` and `gh pr view` - which `branching/scripts/publish-tree-pr.sh`,
`report/scripts/create-or-update.sh`, `ship/scripts/merge-pr.sh` and
`mission/scripts/list-related-prs.sh` all invoke. So a tick that *did* find an ask
would have written the record and the ticket, pushed the branch, and then died at
`pr_failed` - the one abort the workflow calls unrecoverable-by-retry, requiring a
human to open the pull request by hand. The same restriction reaches `/report` and
`/ship`, i.e. `/implement`'s routing seams.

**It is neither fleet-wide nor permanent, and that is the hard part.** 80 minutes
earlier the same day, a run at 15:58-16:02 UTC discovered issues #382 / #384 / #387
through `gh issue list` and opened and auto-merged PRs #389-391 through
`gh pr create` / `gh pr merge` - the identical code paths, working. The GitHub
capability therefore varies from session to session, which means this cannot be
diagnosed from a single failing run, cannot be reproduced on demand, and will
present as an intermittent "the routine did nothing again" with a machine-readable
reason buried in a session nobody reads. A per-session capability treated as a
static one is the defect; the REST fallback that works under the restricted policy
is available in every session measured so far.
