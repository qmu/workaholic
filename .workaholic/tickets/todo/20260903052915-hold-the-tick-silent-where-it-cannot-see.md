---
created_at: 2026-09-03T05:29:15+09:00
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
