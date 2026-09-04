---
created_at: 2026-09-03T05:29:15+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread
merge_policy:
verification_handoff: 
---

# Hold the tick silent where it cannot see

## Overview

A tick that announces on a guess is worse than one that says nothing. The ask states three
bounds in one sentence — nothing on an idle tick, nothing for an item already announced, and a
tie goes to silence — and this ticket makes each of them a behaviour with a reported reason
rather than a sentence in a document.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the step added by the previous ticket.
- `plugins/workaholic/skills/propose/scripts/list-unannounced-closed-asks.sh` — its `ok: false`
  path.
- `plugins/workaholic/skills/notify/SKILL.md` — the exact-string lookup and its refusal to match
  by similarity.

## Implementation Steps

1. An **idle tick** — no candidate — posts nothing and reports `no_candidates`. It never opens
   a root and never says *nothing to report* in the channel.
2. An **unreadable candidate read** (`ok: false`) posts nothing, reports the reader's own reason
   verbatim, and is never rendered as `no_candidates`. The two must not read alike.
3. An **ambiguous thread** — more than one thread matching the key, or a key that resolves to
   none — posts nothing and reports `thread_unresolved: <reason>`. The tie goes to silence.
4. A candidate whose `landed[]` could not be read is announced only if the sentence can still be
   true without the unresolved field; otherwise it is held and reported. Never announce with an
   invented name or time.
5. Report every held candidate with its own word, so a quiet tick and a blind one are
   distinguishable in the run report.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- An idle tick and an unreadable read produce different reported words and no post.
- An unresolved or ambiguous thread produces no post.
- Every held candidate is named with the reason it was held.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic cases in `node scripts/test-workflow-scripts.mjs` over the reader's refusal paths.
- A drill case asserting no post on an unreadable read.

**Gate** — what must pass before approval:

- No path renders an unreadable read as an empty one.

## Considerations

- This repository has twice measured a reader rendering its own blindness as *nothing found*.
  The bound is written here as behaviour precisely because prose did not hold it before.

## Final Report

Development completed as planned. Each of the ask's three bounds is now a behaviour with its own
reported word rather than a sentence in a document, and a fourth rides beside them.

An **idle tick** reports `no_candidates`, opens no root and says nothing in the channel about
having nothing to say. An **unreadable candidate read** reports the reader's own reason verbatim
and is never rendered as `no_candidates`. An **unresolved or ambiguous thread** posts nothing and
reports `thread_unresolved: <reason>` — the tie goes to silence, and case 4's keyed root is
refused here by name. A candidate whose `landed[]` could not be read is `held: <reason>` unless
the sentence stays true without it, so no reply ever carries an invented name or time. Every held
candidate is reported with its own word, which is what makes a quiet tick and a blind one
distinguishable in the run report.

The reader's refusal paths carry hermetic cases in `node scripts/test-workflow-scripts.mjs` (a
refused listing, and an unreadable timeline held apart from a hand-closed item), and
`verify-announced-asks` gained the two matching drill rows plus a **breaker**: wire the refusal
to answer with an empty candidate list, and a blind hour becomes indistinguishable from a quiet
one. The register row moved to `yes`.

### Discovered Insights

- **Insight**: The reader has two independent blindness surfaces, one nested inside the other —
  the listing, which decides whether there are candidates at all, and the per-candidate
  timeline, which decides what closed each one. They need separate words (`ok: false` with its
  reason, and `landed_read: timeline_unreadable`) because they hold different things: the first
  holds the whole tick, the second holds one candidate. Collapsing them would make a single
  unreadable timeline silence an hour that had other announceable items in it.
  **Context**: The same shape recurs wherever a bounded per-item read hangs off a listing.

