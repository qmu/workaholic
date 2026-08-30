---
created_at: 2026-08-30T04:28:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# Refuse a pull request a person has already reviewed

## Overview

PROPOSED. This is the one bound the widening genuinely adds, and it belongs to the
widening rather than to the act it widens. An `undelivered` unit's pull request was
refused by a **transport** — nobody is looking at it. A `queue_drained` unit's may be
one a person is **mid-review** on, and a push resets an approval.

So `catch-up-claim.sh` gains one refusal word: the pull request carries a submitted
review. Every existing refusal, the identity bound and the `content` refusal stay
byte-identical — the writer's contract is added to, never rewritten.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — the writer; the new
  refusal joins its existing list and its header's refusal table
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one transport
  (`rules/shell.md`: never `gh pr …`, which is GraphQL-backed and a web session may
  403 mid-run)
- `plugins/workaholic/skills/drive/reference/claims.md` — the refusal table to extend

## Implementation Steps

1. Derive the fact from the **one REST seam**: the pull request's reviews, read
   through `gh-rest.sh api`. Never `gh pr view`.
2. Refuse by name with the branch **byte-identical** and **exit 0** — nothing
   written, no worktree left, no ref touched — exactly as every other bound refuses.
3. Place the check where the other bounds sit, so a refusal short-circuits before any
   worktree is attached rather than after.
4. An **unreadable** review lookup must not read as *no review*: name it as its own
   reason and refuse, because a wrong "nobody has reviewed" pushes over somebody's
   approval while a wrong refusal only delays a unit — the three-valued discipline
   the merged-pull-request lookup already records.
5. Record the word in `claims.md`'s refusal table and in `CLAUDE.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A pull request carrying a submitted review is refused by its own word, branch
  byte-identical, exit 0
- An unreadable review lookup refuses under its own reason, never as *no review*
- Every pre-existing refusal, the identity bound and `content_conflict` are unchanged
- A pull request nobody has reviewed is caught up exactly as before

**Verification method** — the commands/tests/probes that prove them:

- The drill rows added by this mission's last ticket
- `git diff` on `catch-up-claim.sh` showing only additions to the bound list
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No `gh pr` / `gh issue` / `gh repo` invocation (the suite fails on one)

## Considerations

- "Submitted review" needs a decided meaning: an approval and a changes-requested
  review are both a person's attention; a pending review nobody submitted is not, and
  a bot's review is not a person's. Decide it explicitly, name the decision in the
  script's header, and prefer the safer reading where the seam is ambiguous.
- The far commoner case is a pull request nobody has opened, which must stay free —
  a bound that refuses most units would remove the widening's whole value.
