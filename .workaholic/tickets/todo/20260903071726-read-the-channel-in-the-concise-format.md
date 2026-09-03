---
created_at: 2026-09-03T07:17:26+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: pay-only-the-operative-cost-on-every-tick
merge_policy:
verification_handoff: 
---

# Read the channel in the concise format

## Overview

The tick needs author, timestamp and text. The connector's default detailed format adds
reactions and thread metadata for every message, on every tick. Naming the concise format in the
command is free and changes no behaviour the tick depends on.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §1, the Slack turn: the one place the
  channel is read
- `plugins/workaholic/skills/notify/SKILL.md` — owns what the loop reads and posts on Slack

## Implementation Steps

1. Confirm which fields §1 actually consumes: the author (to skip the loop's own posts by
   shape and to compose `subject: person:<name>`), the timestamp (the `ts` half of the
   `slack-ref`, which is also the receipt's `thread_ts`), and the text.
2. Name the concise format on the channel read in §1.
3. Leave the thread read untouched: *read the thread first* before replying needs the replies,
   and that is a different call on a different coordinate.
4. Leave every search rule alone — the private-inclusive, `include_bots: true`, exact-string,
   at-most-two-queries rules are `workaholic:notify`'s and are not this ticket's.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The channel read names the concise format.
- Every field §1 consumes is still available.
- The thread read and every search rule are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/infinite-development.md` §1 against the three conditions.
- One live tick sweeps, replies and reacts as before.

**Gate** — what must pass before approval:

- No search or thread rule moved.

## Considerations

If the concise format omits a field §1 consumes — the reaction set is used only for the
loop's own stamps, but the author's shape test reads the message text — the honest outcome is to
say which and keep the detailed format, reporting the measurement rather than forcing the change.
