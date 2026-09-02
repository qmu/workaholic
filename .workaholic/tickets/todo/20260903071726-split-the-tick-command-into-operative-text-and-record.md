---
created_at: 2026-09-03T07:17:26+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: pay-only-the-operative-cost-on-every-tick
merge_policy:
verification_handoff: 
---

# Split the tick command into operative text and record

## Overview

`commands/infinite-development.md` is 1,775 words / 11,291 bytes and the loop runs in one
session that never resets, so the body is re-paid every five minutes. Much of it is measurement
and rejected alternatives — load-bearing for a person deciding whether to change a rule, and not
for a run applying it. This is the largest single lever, because it is paid on every tick whether
or not anything happened.

**The split has one hard bound and the ticket exists to hold it.** `workaholic:notify` states
that *the command is the ceiling*, and the routine-template rule (2026-09-02, ticket
20260902043747) says a rule the run must **read to act** is inlined byte-identical while a
**provenance citation** stays a citation. So what moves is the record — measurements, rejected
alternatives, the history of why a rule reads as it does. No operative instruction moves, and
nothing is replaced by a summary: a paraphrased ceiling is a third version of the rule.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the command being split
- `plugins/workaholic/skills/loops/SKILL.md` — the skill that owns the premise; gains the
  `reference/` page beside it (the directory does not exist yet)
- `plugins/workaholic/skills/notify/SKILL.md` and `reference/notifications.md` — the split this
  copies, named by the ask itself
- `scripts/test-workflow-scripts.mjs` — pins command bodies against drift

## Implementation Steps

1. Read the whole command body and classify every paragraph: **operative** (a run must read it
   to act) or **record** (why the rule reads as it does). Write the classification down in the
   pull request — it is the reviewable part.
2. Create `skills/loops/reference/` and move the record there verbatim. Nothing is rewritten,
   condensed or summarised on the way.
3. Leave every operative rule in the command **byte-identical**, including the four inlined
   ceilings the routine-template rule requires (the Read-tool rule, the Japanese rule, the post
   shapes, the reap and cadence rules).
4. Link the reference page from the command once, as a citation — a name to open when a person
   is deciding, never a lookup a run must resolve to act.
5. Report the before/after byte count of the command body in the pull request, so the lever is
   measured rather than asserted.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every operative rule is still in the command body, byte-identical.
- No operative rule is replaced by a summary or a pointer.
- The record is in `skills/loops/reference/` in full, nothing lost.
- The command's byte count is reported before and after.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes, including the post-format pins.
- `diff` the retained operative paragraphs against the pre-split body: byte-identical.
- `wc -c plugins/workaholic/commands/infinite-development.md` before and after.

**Gate** — what must pass before approval:

- Not one operative sentence moved out of the command.

## Considerations

The measurements moved here are the same ones a later reader needs to argue against a rule; the
value of the split is entirely in *where* they live, so a move that loses a paragraph is worse
than no split at all.
