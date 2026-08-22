---
created_at: 2026-08-22T13:03:05+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: announce-one-event-once-and-give-its-root-a-shape
merge_policy:
verification_handoff: 
---

# Give the implement no-thread root a readable shape

## Overview

When `/specificate`'s thread lookup finds nothing, it posts a **description root** first — a
marker, a linked title, one sentence saying what the item asks for — and replies its finish
line into it. `notify/reference/notifications.md` states plainly that "`/implement`'s case-4
finish line is unaffected and stays its own keyed root", and gives the reason: the routine
prompt does not name the shape.

The measured result is a channel-top-level message that opens with a status emoji and a pull
request number, gives a reader nothing to read and nothing to answer, and ends in a bare
sixty-character machine key — beside `/specificate` roots that read properly. The design
knowingly ships the shape it rejected elsewhere and documents why; that reason is a
constraint to lift, not a justification.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — *The description root*
  (`/specificate`, case 4) and the `/implement` finish shapes; the sentence exempting
  `/implement` is what this ticket removes.
- `plugins/workaholic/skills/notify/SKILL.md` — *One thread per feedback item*, case 4.
- `plugins/workaholic/skills/workaholify/routines/implement.md` — names one post format
  today; it must name the root as `[Specificate]`'s template already does.
- `plugins/workaholic/skills/workaholify/routines/specificate.md` — the existing root wording
  to mirror, pinned byte-identical by the suite.
- `scripts/test-workflow-scripts.mjs` — the pin that must cover the new copy.

## Implementation Steps

1. **Read both templates and both copies of the root before changing anything**, and record
   what `/implement` posts today in case 4 versus what `/specificate` posts. The exemption's
   stated reason (the routine prompt does not name the shape) is the thing to verify.
2. Define `/implement`'s case-4 root on the description root's pattern: a marker, the linked
   item title, one sentence, the session URL. Reuse the existing shape rather than inventing
   a second wording — a diff between copies is a drift to fix.
3. Reply the finish line (`🟢` / `🚀` / `🟡` / `🔴`) into that root, exactly as
   `/specificate` replies `🔵 Proposed` into its own.
4. Keep the no-mention-token rule on the root: a `<@U…>` resolving to the Claude app
   re-triggers the app on the routine's own post.
5. Preserve "exactly one finish per thread" — the root is the announcement's header, not a
   second announcement, which is the same argument `/specificate`'s root already carries.
6. Name the format in `workaholify/routines/implement.md` (it will then name two, as
   `specificate.md` does) and extend the byte-identical pin in the suite.
7. Update `CLAUDE.md` and the affected `rules/` document in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/implement`'s case-4 post is a root with a linked title and a description sentence, with
  the finish line as its threaded reply.
- The root carries no mention token.
- `implement.md` names the root format and it is byte-identical to
  `notify/reference/notifications.md`'s copy.
- A unit still posts exactly one finish per thread.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the byte-identical pin)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- Read-back of both templates and both root copies against the four criteria.

**Gate** — what must pass before approval:

- All four criteria hold and the suite is clean.

## Considerations

- Whether the root still renders the `` `fb:<stem>` `` key is **not** decided here: mission
  `take-the-dedup-key-out-of-the-read-post` owns that question and is already queued. This
  ticket changes the root's shape and leaves the key line exactly as that mission finds it.
- Drive this after its sibling: with the duplicate announcement fixed, case 4 is rarer, and
  the root's shape is then the only thing left wrong with it.
