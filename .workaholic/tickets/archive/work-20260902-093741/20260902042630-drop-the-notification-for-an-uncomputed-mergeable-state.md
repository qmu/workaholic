---
created_at: 2026-09-02T04:26:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Drop the notification for an uncomputed mergeable state

## Overview

PROPOSED. The tick posted that some pull requests could not be merged because GitHub had
not yet computed mergeability. The operator: that is not worth a notification. An unknown
mergeable state means only that the pull request cannot be included in **this pass's**
conflict resolution — GitHub computes it asynchronously and the next tick will read it.

So `unanswerable` stops being a thing a person is told and becomes a thing that removes a
row from the pass. It stays in the run report, where it is evidence; it leaves the channel.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` — a notification's bar is that its reader can act on it

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — the one derivation of
  `clean | mechanical | content | unanswerable`; unchanged, it keeps answering the class.
- The step the sibling diagnosis ticket names as the composer of the line.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — that step's spec, where the
  candidate filter and the question wording live.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the question seam; an
  `unanswerable` row must reach no key here.
- `plugins/workaholic/skills/moderate/SKILL.md` and `CLAUDE.md` — the prose that describes
  what the step asks about.

## Implementation Steps

1. From the sibling ticket's mapping, open the step that composed the line.
2. Filter `unanswerable` out of that step's **question candidates**, at the candidate
   selection rather than at the post: a row that never becomes a candidate cannot become a
   key, and filtering at the post leaves the key recorded as asked.
3. Keep the row in the step's own `summary` and in the run report, counted by its class, so
   the reading is still visible to whoever opens the session. The operator's objection is to
   the notification, not to the fact.
4. Do not let the removal silence a *readable* conflict: `content` and `mechanical` rows are
   untouched by this ticket, and a test asserts a `content` row still reaches its
   destination after the filter.
5. Update the step's spec in `moderate/reference/workflow.md`, `workaholic:moderate` and
   `CLAUDE.md` in the same change.
6. Add a hermetic assertion: a pass containing one `unanswerable` row and one `content` row
   asks about the second and not the first.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An `unanswerable` mergeability produces no question and no channel line.
- It is still counted in the step summary and the run report.
- A `content` row's existing behaviour is byte-identical across the change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The new assertion fails if the filter is applied at the post rather than at candidate
  selection (the key would be recorded).

## Considerations

- `unanswerable` is the absence of a reading, and this repository's standing rule is that
  such a word is reported, never acted on. Dropping the *notification* is consistent with
  that: it is still reported, just not to a person who cannot act on it.

## Final Report

Development completed as planned, against a **corrected reader**: the class is
`pulls-state.sh`'s `blocked_by: "unknown"`, not `claim-mergeability.sh`'s `unanswerable`.

The Key Files named `claim-mergeability.sh` as "the one derivation of `clean | mechanical |
content | unanswerable`". That reader never reaches these steps. The sibling diagnosis ticket
established it and this ticket was implemented on the corrected mapping: the two steps that
composed the operator's quoted line read GitHub over REST through
`moderate/scripts/pulls-state.sh`, whose vocabulary is `conflict | review | checks | draft |
behind | unknown`, with `unknown` defined as `mergeable == null`. `claim-mergeability.sh` is a
*local* `git merge-tree` reading, and `step-stuck-prs.sh`'s own header says why it cannot be
used here (the class needs a branch ref, and a network read inside these steps was refused on
a measurement). **A filter written against the word the ticket named would have matched
nothing and the operator would have seen the same post again** — the exact failure the
diagnosis ticket exists to prevent.

### Two channel surfaces carried it, and both are closed

The line reached a reader by two paths, and closing one would have left the other:

1. **The question** — `step-stuck-prs.sh` put every `unknown` row into `needs_agent`, which
   `human-checkin` renders as a `🙋` post. Its decision text was *"GitHub has not computed
   mergeability yet — re-read before acting"*, which names no act any addressee can take.
2. **The root change line** — `step-merge-conflicts.sh` appended `UNKNOWN_NOTE`
   (`", N not yet computed by GitHub"`) to its `event`, and the `event` is precisely the line a
   person sees.

### The filter is at candidate selection, and that is observable

`ask-question.sh` records a key as asked when the question is **composed**, so a post-time
filter would have left the key spent while the row reached nobody — asked and unasked at once.
The rows are therefore dropped before the candidate set is built, and they leave the `ask_key`
digest with it: the digest is over the sorted `<number>:<blocked_by>` set, so an uncomputed row
left in it could change the key of a question about a *different* pull request and re-ask a
settled subject for a reason no reader could see.

**The test asserts the placement rather than the effect**: a pass carrying one uncomputed row
and one conflicted row produces an `ask_key` **identical** to a pass carrying the conflicted
row alone. A post-time filter fails that row while passing every other one.

### A pass holding only uncomputed rows reports `ok`

This was not in the steps and the acceptance criteria require it. `blocked` rows are what
`render-tick-post.sh` derives `impaired[]` from, and a changed impairment is one of the four
gates that open a root — so leaving the step `blocked` with an empty `needs_agent` would have
replaced a question about an uncomputed row with an **impairment line** about it. Same reader,
same non-fact, different shape. The step now answers `ok` with reason
`mergeability_uncomputed`, mirroring the sibling step's existing branch, and never claims those
pull requests are mergeable.

### Deviation: the count rides its own field, not the summary

Step 3 said "keep the row in the step's own `summary`". It is kept in an **`uncomputed` field**
instead, and the reason is measured and already in the tree. `render-tick-post.sh` compares
`(step, status, stabilized summary)` for the impairment diff, and `step-merge-conflicts.sh` had
this very count in its compared summary until 2026-09-01 (ticket `20260901122448`), when it was
removed because GitHub settles `mergeable` on its own schedule and every settlement opened a
root — measured across nine consecutive ticks while the repository did not move. Putting it in
`stuck-prs`'s summary would have re-created that defect in the sibling step. The field is the
shape `merge-conflicts` already uses, so the run report and every other reader still have the
number; only the compared string stays free of it.

### Verification

- `node scripts/test-workflow-scripts.mjs` — **6040 passed, 0 failed** (7 new rows).
- `sh scripts/e2e/loop-drill.sh verify-all` — **43 drills, 0 failed, 33 proved.**
- `node scripts/build-plugins/build.mjs` / `verify.mjs` — regenerated and clean.

**`verify-tick-thread` went red first, and it was right to.** Its breaker patches
`step-stuck-prs.sh`'s final argument line by an exact `sed` anchor, and that line gained
`"$uncomputed"`. The anchor stopped matching, half B of the breaker silently did not apply, and
the drill reported `noisy=no` — *the rows above prove nothing* — which is precisely the job a
breaker exists to do. The anchor was **re-anchored, not relaxed**: a loose pattern would be a
breaker that stops noticing.

The dead `unknown` arms in the headline and the decision program were **deleted, not left
unreachable** — a dead branch still reading "with mergeability not yet computed" is the stale
sentence a later session restores the behaviour from — and `UNKNOWN_NOTE` was deleted rather
than emptied, for the same reason.

### Discovered Insights

- **Insight**: Filtering a notification has two distinct placements with different
  consequences, and only one of them is correct here: before the candidate set is built, or at
  the post. Because `ask-question.sh` records the key at composition time, a post-time filter
  produces a question that is simultaneously suppressed and marked asked.
  **Context**: This applies to every future "stop telling people about X" change in this tick.
  The observable difference is the `ask_key`, which is why the assertion is on the key rather
  than on the absence of a post — an absence assertion passes for both placements.

- **Insight**: Suppressing a `🙋` question is not enough to take a fact off the channel. A
  step's `blocked` status feeds `impaired[]`, and a changed impairment is itself a root gate —
  so a step left `blocked` with nothing to ask replaces one channel line with another.
  **Context**: `status` is a channel surface here, not just an internal health word. Any step
  that filters its own candidates to empty must also reconsider the status it reports.
