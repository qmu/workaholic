---
created_at: 2026-08-07T10:58:00+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission: slim-commands-skills-and-docs-for-ai-agent-use
merge_policy:
---

# Let Final Report edits pass on foreign-authored tickets

## Overview

`hooks/validate-ticket.sh` fires on every `Write|Edit` to a `todo/` ticket and
rejects the file when its `author:` is not the current `git config user.email`.
That floor is right for ticket *creation*, but it also fires when a drive run
appends the `## Final Report` to a ticket somebody else authored — measured
2026-08-07 while driving a mission whose tickets were proposed by the cloud
routine (`author: noreply@anthropic.com`): the append was flagged although the
run must not rewrite the artifact's provenance. Ownership moved to `assignees`
(P2), so the author-matches-me check should apply only to a ticket that is
**new to git** (untracked at that path), not to an edit of an existing one.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` — scope the author check to new files (git-untracked), keeping every other floor as is.
- `scripts/test-workflow-scripts.mjs` — cover: edit of an existing foreign-authored todo ticket passes; a new ticket with a mismatched author is still rejected.

## Implementation Steps

1. In `validate-ticket.sh`, detect whether the target path is tracked in git; run the author-equality check only for an untracked (new) ticket.
2. Keep the rejection message and every other validation unchanged.
3. Add the two test cases above.

## Quality Gate

**Acceptance criteria:**

- Appending a Final Report to an existing ticket authored by another identity passes the hook.
- Creating a new ticket whose `author:` is not the runner's email is still rejected.

**Verification method:**

- `node scripts/test-workflow-scripts.mjs` passes with the two new cases.

**Gate:**

- No other validation loosened; provenance is never rewritten to satisfy the hook.
