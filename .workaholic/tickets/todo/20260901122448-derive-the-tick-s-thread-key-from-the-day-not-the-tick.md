---
created_at: 2026-09-01T12:24:48+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff: 
---

# Derive the tick's thread key from the day, not the tick

## Overview

PROPOSED. The `🔎 Moderation` root is keyed `tick:<tick-id>` where the id is that tick's own
timestamp, so `tick:…-160000` can never match `tick:…-150000` and the stateless exact-string
lookup takes case 4 — *open a new root* — every hour, by construction. Measured on a consuming
repository: 14 roots in one window, 12 of them carrying zero questions. This derives the key
from the **day** instead, in one place, so the machinery that already exists to reply into a
standing thread becomes reachable. It changes the key and nothing else.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — stamps `"token": "tick:<id>"`; the one place the key is composed today.
- `plugins/workaholic/skills/moderate/scripts/lib/speaking-window.sh` — already derives `WORKAHOLIC_QUIET_TZ`; the day boundary a reader perceives is the one it already resolves.
- `plugins/workaholic/skills/moderate/scripts/lib/` — home for the new one derivation.

## Implementation Steps

1. **Reproduce the failure first.** Render two ticks an hour apart and show their `token`
   values differ (`tick:…-150000` vs `tick:…-160000`), so the exact-string lookup can only
   ever take case 4. Capture that as the baseline the change has to move.
2. **Localize.** Confirm `render-tick-post.sh` is the only composer of the key, and that no
   consumer stores or compares it beyond the lookup.
3. Add `lib/tick-thread-key.sh` as the **one** derivation: `tick-day:<YYYYMMDD>` for the tick
   id's day in `WORKAHOLIC_QUIET_TZ`, composed through `lib/speaking-window.sh` rather than a
   second TZ read. It takes a tick id and answers a key; it reads no clock of its own.
4. Make `render-tick-post.sh` read that derivation instead of spelling `tick:<id>`. Its output
   keeps the same field name so no consumer moves.
5. A tick id that is not a timestamp (the sentinel case `lib/tick-iso.sh` already handles)
   must answer a **named refusal**, never a key derived from a date it could not read — a
   wrong key threads an hour into the wrong day's root.
6. Pin in `scripts/test-workflow-scripts.mjs`: two tick ids one hour apart on the same local
   day derive the **same** key; two on either side of the boundary derive different ones; and
   `render-tick-post.sh` contains no literal `tick:` key composition.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two ticks an hour apart on the same `WORKAHOLIC_QUIET_TZ` day derive one identical key.
- Two ticks either side of that day boundary derive different keys.
- An unparseable tick id answers a named refusal and no key.
- The key is composed in exactly one file; nothing else spells it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new rows above.
- `bash plugins/workaholic/skills/moderate/scripts/lib/tick-thread-key.sh <id>` run directly
  against each case.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **The reporter's proposed mechanism is a hypothesis, not this ticket's design.** The ask
  proposes carving the tick out of `workaholic:notify`'s recency prohibition. A **day-stable
  key** reaches the same outcome with the ban untouched: the lookup stays an exact-string
  match on a key the tick derives, so nothing recency-shaped is introduced and no carve-out is
  needed. If the day key turns out not to resolve the thread, the carve-out returns as a
  separate, argued change.
- **The day is the operator's, not UTC.** The log's day files are UTC; the reader's day is
  `WORKAHOLIC_QUIET_TZ`, which the speaking window already derives. Keying on UTC would break
  a root mid-evening for a JST reader. The cost of the choice is that the key and the log file
  can name different days for the same tick — stated rather than hidden.
- This ticket changes the key only. The posting behaviour it unlocks is the next ticket, and
  neither is worth shipping without the other.
