---
created_at: 2026-09-02T04:26:30+00:00
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
