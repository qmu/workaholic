---
created_at: 2026-09-08T14:24:54+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage
merge_policy:
verification_handoff: 
---

# Discover and classify new replies before claiming thread coverage

## Overview

Add a bounded private-inclusive discovery path for new human replies inside existing threads, then
read each changed thread before deciding whether the reply is a question, ask, answer, or reaction-only message.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — distinguish discovered replies from assumed provider coverage.
- `plugins/workaholic/skills/transport/scripts/adapters/qfs.sh` — query channel deltas and thread messages through the selected binding.
- `plugins/workaholic/commands/infinite-development.md` — classify a reply only after reading its thread context.

## Implementation Steps

1. Reproduce the measured miss where channel history omits a new reply under an older root.
2. Discover changed thread coordinates independently of an already-known-thread list, within the same bounded overlap window as top-level intake.
3. Apply the existing human, own-post, durable capture, and dedup rules to reply events.
4. Read the complete changed thread before routing the reply to answer, capture, moderation-answer, or reaction behavior.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A new unmentioned human reply under an existing private thread is discovered once and classified with its thread context.

**Verification method** — the commands/tests/probes that prove them:

- Run transport and coordinator fixtures where channel history omits replies, overlap repeats them, and bot-authored replies are present.

**Gate** — what must pass before approval:

- The coverage report says complete only when the discovery operation can find replies whose coordinates were not already known.

## Considerations

Do not replace the bounded delta with full-channel or every-thread scans; partial provider coverage must remain explicit.
