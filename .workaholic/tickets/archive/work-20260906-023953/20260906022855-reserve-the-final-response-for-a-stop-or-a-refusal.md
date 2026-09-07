---
created_at: 2026-09-06T02:28:55+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-each-tick-in-the-originating-codex-chat
merge_policy:
verification_handoff: 
---

# Reserve the final response for a stop or a refusal

## Overview

`commands/infinite-development.md` tells the tick to **end**, and `work/SKILL.md`'s
substitution table renders that off Claude Code as *execute one tick and end*. On a harness
where a final response ends the active turn, obeying that literally is what killed the loop:
the session ran its tick, emitted a final answer, and the operator's next status arrived only
because they asked for it.

In the native-parent branch, **end means return control to the coordinator**. A final response
is reserved for exactly two events: an explicit stop, and a named inability to continue.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the running loop's own reporting and recovery

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the tick body carrying the *end*
  instruction; the ceiling for what a tick posts.
- `plugins/workaholic/skills/work/SKILL.md` — the substitution table row that renders *end*
  off Claude Code, which must render it per branch rather than once.

## Implementation Steps

1. Make the substitution table's *end* row **branch-aware**: under the external supervisor or
   a scheduled task, ending the run is correct and the clock re-invokes it; under the
   native-parent branch, *end* returns to the coordinator's own loop and emits nothing final.
2. State the two events that **do** earn a final response, and no others: an explicit stop from
   the operator, and a named inability to continue (a missing mechanism the startup report
   already named).
3. Make an ordinary **question or correction during the loop** an answer in commentary: it
   neither cancels the loop nor resets the anchor. Say so where the tick's channel turn is
   specified, so the two paths are not left to be inferred.
4. Make an **explicit stop** stop further dispatch and state **what remains running** — the
   roles still in flight and their child identifiers — rather than ending silently.
5. Add nothing to the tick's ceiling: the shapes it may post are unchanged, and commentary in
   the originating conversation is not a Slack post.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The *end* instruction renders per branch; under the native-parent branch it never means a
  final response.
- Only an explicit stop and a named inability to continue produce a final response.
- A question answered mid-loop leaves the loop running and the anchor unmoved.
- A stop names what is still running.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the ceiling pins over the command bodies.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No post shape is added to or removed from `commands/infinite-development.md`'s ceiling.

## Considerations

- The distinction is only meaningful where a final response ends the turn; on a branch where
  the clock re-invokes the tick, the existing wording is already correct and must not be
  rewritten around this one.

## Final Report

Development completed as planned.

The substitution table's *end* row no longer renders once for every non-Claude session: it points
at `work/SKILL.md`'s new *What "end" means, and the two events that earn a final response*, whose
table renders the word per branch — return control to the coordinator under the native-parent
branch, end the tick or the run or the process everywhere the clock re-invokes the body. The two
events are stated there, the mid-loop question and the explicit stop are stated in
`commands/infinite-development.md` §1 where the channel turn is specified, and §2's *end the turn*
now names the branch's word rather than a final answer.

**The gate held**: no post shape was added to or removed from the ceiling. The `💬`, `📥 受理` and
`🟢 Implemented` blocks are byte-identical, and the paragraph added to §1 says explicitly that
commentary in the originating conversation is not a Slack post.

### Discovered Insights

- **Insight**: one hermetic run of `node scripts/test-workflow-scripts.mjs` reported
  `6620 passed, 1 failed` and an immediate re-run over the identical tree reported
  `6621 passed, 0 failed`; a third run agreed. The failing row's name was lost to the pipe that
  captured only the tail.
  **Context**: the suite is asserted to be hermetic, so a non-reproducing failure is either a
  test with a real timing dependency or a shared temp path colliding with a concurrent run — both
  worth knowing before somebody reads a single red run as a regression. Recorded rather than
  chased, because nothing in this mission touches the suite's own machinery.
