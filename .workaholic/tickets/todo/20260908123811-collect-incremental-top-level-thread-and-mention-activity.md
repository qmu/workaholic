---
created_at: 2026-09-08T12:38:11+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
---

# Collect incremental top-level, thread, and mention activity

## Overview

Collect the union of new top-level messages, new replies in tracked threads, and new mentions addressed to each bound bot identity, with a bounded overlap window and private-inclusive reads.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — inbound turn orchestration.
- `plugins/workaholic/skills/qfs-slack/` — message, search, and thread queries.
- `plugins/workaholic/skills/propose/` — reuse the inbound sweep's established human/own-post filters.

## Implementation Steps

1. Measure which live Slack/QFS operations can enumerate messages, replies, and mentions for each binding.
2. Define start, continuation, expiry, and reopening rules for tracked threads.
3. Union all three sources before applying human, own-post, and overlap filters.
4. Report API calls and partial coverage per source rather than claiming a complete changelog.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A new human reply is discovered even when the root alone contains the mention.
- Top-level, thread, and mention sources preserve source coordinates and coverage status.

**Verification method** — the commands/tests/probes that prove them:

- Run bounded fixtures with private threads, paginated search, and unmentioned follow-up replies.

**Gate** — what must pass before approval:

- No source is described as covered when its live operation is unavailable.

## Considerations

Slack search aggregation is not a complete event log; event subscriptions may replace polling only when the repository can actually host and verify them.
