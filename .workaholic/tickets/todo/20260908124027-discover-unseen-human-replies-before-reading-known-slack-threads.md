---
created_at: 2026-09-08T12:40:27+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
---

# Discover unseen human replies before reading known Slack threads

## Overview

Add a bounded private-inclusive discovery query for new human replies inside existing Slack threads before the inbound turn reads thread context or decides how to act.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — inbound Slack discovery order and decision routing.
- `plugins/workaholic/skills/qfs-slack/` — private-inclusive reply discovery and thread reads.
- `plugins/workaholic/skills/propose/` — reuse human, own-post, overlap, and dedup filters.

## Implementation Steps

1. Reproduce the missed-reply case where channel history sees the root but omits a newer thread reply.
2. Add a bounded reply-discovery operation that does not require the thread coordinate to be known in advance.
3. Apply the same overlap, human/own-post, and dedup rules as top-level intake.
4. Read the discovered reply's thread before classifying it as an answer, ask, reaction, or conversational reply.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A new human thread reply is discovered without a new top-level message or repeated mention.
- Discovery precedes thread reading and action classification.

**Verification method** — the commands/tests/probes that prove them:

- Run fixtures for private threads, unmentioned replies, overlap replay, and bot-authored replies.

**Gate** — what must pass before approval:

- A known-thread-only reader cannot satisfy the discovery coverage test.

## Considerations

Keep the reply query bounded; do not replace the missed path with a full-channel history walk.
