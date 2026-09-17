---
created_at: 2026-09-08T14:24:54+09:00
status: done
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

## Final Report

Development completed as planned.

`list_thread_changes` is the transport's ninth operation: it asks which threads changed inside
the same bounded overlap window as the top-level delta, by their own coordinates and
independently of any known-thread list. `observe-channel.sh` reads each changed thread whole,
captures it through the existing dedup and human/own-post filters, and routes each new reply
`moderation_answer` / `answer_to_loop` / `reaction_only` / `needs_judgement`. The fan-out is
bounded (`WORKAHOLIC_THREAD_FANOUT`, default 5) and a truncated page is reported.
`coverage.threads.status` is `covered` only when the discovery operation ran, `partial` with its
own reason otherwise, and `coverage.complete` is derived from all three axes.

**Commit boundary, stated**: the implementation of this ticket was already present in the
previous ticket's archive commit — the two were driven in one session and the archive seam stages
the whole worktree. The work is unchanged; only its commit boundary moved.

### Discovered Insights

- **Insight**: The old reading was not merely incomplete, it was *named* incomplete and still
  consumed as coverage: `covered_when_returned_by_channel_delta` said in its own value that a
  reply is seen only if the channel delta happens to carry it, and every consumer read the field
  as "threads: covered".
  **Context**: A status value that describes its own precondition is a status nobody reads. The
  replacement makes `covered` mean one checkable thing and puts the precondition in `discovered`.
- **Insight**: The thread capture had to carry the *channel* cursor forward unchanged. Writing
  the pre-advance value back — the obvious reading of "this capture is about threads, not the
  channel" — rewinds the binding and re-delivers the page the channel capture just took, every
  tick, forever.
  **Context**: `capture-inbox.sh` advances the one binding cursor whatever the caller is
  capturing; there is no per-source cursor, and adding one would be a second store of the same
  fact.
- **Insight**: Classification belongs after the whole thread is read, and the last class belongs
  to the agent. The root's shape mechanically separates the loop's own `🙋` from its other posts,
  but a reply under a *human* root is a question or an ask only a reader can tell apart — so it
  is routed `needs_judgement` rather than guessed by a script.
  **Context**: This is the same split the repository already draws between a file test and a
  judgement about behaviour.
