---
created_at: 2026-08-22T13:03:05+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: announce-one-event-once-and-give-its-root-a-shape
merge_policy:
verification_handoff: 
---

# Announce a unit's finish once, not once per stem

## Overview

`workaholic:notify`'s SKILL says: "Several stems → post into each thread, once per stem per
event." Measured twice, and the second measurement is the one that sets the scope.

**First report**: a unit resolved to two stems and the channel carried the identical finish
line twice within four seconds — one into the thread that was found, one as a new root because
the second stem matched nothing. There the two stems were two records of one request, captured
months apart by different seams, so the rule delivered "announce an event as many times as the
corpus happens to hold records of it".

**Second measurement (2026-08-22), and it makes this deterministic rather than incidental.**
The same duplicate appeared 22 seconds apart on a unit whose second stem was a **strategy's
carried-forward `feedback:` ref**. That carry-forward is deliberate and load-bearing:
`/specificate` puts the strategy's refs onto every mission it emits, because
`attributed-work.sh` attributes work back to a direction through
`strategy.feedback[] ∩ artifact.feedback[]` and there is no other link. So
`unit-feedback-stems.sh` now resolves **every strategy-attributed unit** to two or more stems,
and "once per stem per event" turns each of them into two announcements — the second one always
the naked root, because a strategy's stem has no description root of its own to thread into.

The duplicate is therefore not a corpus accident that a tidier stream would remove. It is
guaranteed for every unit the loop produces on its own, and it grows with the number of refs a
strategy carries.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — *Which thread an `/implement` unit's posts
  land in*: the "once per stem per event" rule and the `` `unit:<unit-id>` `` no-stem key.
- `plugins/workaholic/skills/notify/reference/notifications.md` — `/implement`'s finish
  shapes, which must state where the one post goes when several stems resolve.
- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — resolves a unit's
  artifacts to deduped stems; the caller's fan-out is what changes, not this resolver.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the per-unit notification outcome the run
  report names.
- `plugins/workaholic/skills/workaholify/routines/implement.md` — the routine's copy of the
  authorized post formats, pinned byte-identical by the suite.

## Implementation Steps

1. **Reproduce before designing.** Take a unit whose artifacts resolve to two or more stems
   and record what the current rule produces: N posts for one event, and which of them
   threaded. Do not infer this from the rule's wording — run `unit-feedback-stems.sh` on a
   real unit and read the notify contract's fan-out.
2. **Localize.** Confirm the fan-out is the caller's (the `/implement` finish step), not
   `unit-feedback-stems.sh`'s, so the resolver's contract does not move.
3. State the rule as **one finish line per unit per channel**: post into the thread the
   lookup found. Define the tie-break when more than one stem finds a thread — pick one and
   state which, deterministically, so two runs of the same unit choose the same thread.
4. Decide and state what the remaining stems get: a pointer into the chosen thread, or
   nothing. The ask permits either; whichever is chosen must be written down, because the
   silent alternative is what produced the duplicate.
5. Leave the no-stem case untouched — `` `unit:<unit-id>` ``, never keyless.
6. Mirror the wording into `workaholify/routines/implement.md` in the same commit; the suite
   pins the two copies byte-identical.
7. Update `CLAUDE.md` and the affected `rules/` document in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit resolving to several stems produces exactly one finish post per channel.
- The thread chosen when several stems match is deterministic and stated.
- The no-stem `` `unit:<unit-id>` `` path is unchanged.
- The routine template and `notify/reference/notifications.md` carry identical wording.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (pins the routine/notify copies)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `bash plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` on a multi-stem unit,
  read against the new rule.

**Gate** — what must pass before approval:

- All four criteria hold and the suite is clean.

## Considerations

- Deduplicating per event is not the same as deduplicating per record. Two genuinely
  different items in one unit still deserve their own threads; what must stop is one ask's
  duplicate records producing duplicate announcements. State the distinction rather than
  collapsing it.
- The `🔴 Blocked` red-alert dedup is a separate surface with its own signature and is out of
  scope here; the key it renders belongs to mission
  `take-the-dedup-key-out-of-the-read-post`.
