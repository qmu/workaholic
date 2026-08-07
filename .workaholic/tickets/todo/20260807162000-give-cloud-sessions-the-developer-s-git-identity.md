---
created_at: 2026-08-07T16:20:00+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
feedback: [20260807065338-archive-sh-should-auto-push-the-claim-branch-after-archiving.md]
merge_policy:
---

# Give cloud sessions the developer's git identity

## Overview

Measured live (2026-08-07, the first full routine-chain run): a proposal's ticket
carried `assignees: [a@qmu.jp]` (P6, correctly stamped from the Issue assignee), and
the developer's own `[Implement]` routine could not claim it — the cloud container's
git identity is `noreply@anthropic.com`, so `owns.sh` ruled the developer's own
ticket `other` and the run ended 🔴 `ticket_owner_mismatch`. The session pushes and
merges **as** the developer's GitHub account, yet git does not know who it is. Every
personally-assigned ticket is therefore undrivable by the very routine that exists to
drive it.

Fix at the provisioning seam: the web bootstrap (`session-start.sh`) resolves the
session's GitHub login (`gh api user`) through a committed per-repo mapping,
`.claude/git-identities` (`<login>=<email>`, one per line), and sets
`git config user.email` (and `user.name` from the login) **only when the current
identity is unset or the anthropic default** — a developer's real local identity is
never overwritten. Identity enters once, per developer, in a committed file; the
emails are already public in git history, so the file discloses nothing new. The
routine prompts stay four lines.

## Policies

- `workaholic:implementation` / `policies/observability.md` — the failure was loud and named; the fix closes it at the seam that owns provisioning
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX sh, no set -e in the bootstrap

## Key Files

- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the canonical hook; add the identity step beside the gh provisioning step (guarded, non-fatal, idempotent).
- `.claude/hooks/session-start.sh` — the installed copy; must stay byte-identical to canonical (`check-bootstrap.sh` compares).
- `.claude/git-identities` — NEW, committed: `tamurayoshiya=a@qmu.jp`.
- `plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh` — verify it needs no change (byte-compare covers the new step).
- `plugins/workaholic/skills/workaholify/SKILL.md` (bootstrap section) + `reference/bootstrap.md`, `/setup-routines` preconditions — document the mapping file.
- `scripts/test-workflow-scripts.mjs` — cover: mapping hit sets the identity; anthropic default without a mapping stays untouched and non-fatal; a real local identity is never overwritten.

## Implementation Steps

1. Add the identity step to the canonical `session-start.sh`: read login via `gh api user` (skip silently when gh or network is absent), look it up in `.claude/git-identities`, and set `git config user.email`/`user.name` only when the current email is empty or `*@anthropic.com`. No `set -e`; every branch non-fatal; one legible log line each way.
2. Copy the canonical hook over `.claude/hooks/session-start.sh` and commit `.claude/git-identities`.
3. Document the mapping in the workaholify bootstrap section and the setup-routines precondition list.
4. Add the three test cases; run the full local verification set.

## Quality Gate

**Acceptance criteria:**

- A cloud session whose git email is the anthropic default and whose GitHub login is mapped ends up with the mapped `user.email` before any survey runs.
- A session with a real local identity, or with no mapping entry, is untouched and session start never fails.

**Verification method:**

- `node scripts/test-workflow-scripts.mjs` green with the new cases; `check-bootstrap.sh` reports the installed copy canonical.

**Gate:**

- The hook stays POSIX sh with no `set -e` and never blocks session start; the mapping file's absence is the status quo, not an error.
