---
created_at: 2026-09-09T20:45:00+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-a-native-tick-from-reconciled-evidence-not-from-a-worker-s-word
feedback: [20260909125918-repair-the-native-work-loop-s-control-delivery-and-truthful-reporting.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff:
---

# Emit act-effect's refused word in its documented shape

## Overview

MINTED while driving `20260909130138-reconcile-a-completion-claim-against-merges-claims-and-the-queue.md`
(2026-09-09). `drive/scripts/act-effect.sh` documents its delivery answer as
`taken` / `refused:<word>` / `pending` / `unavailable` / `unreadable`, and its own header says
each act's word is *carried verbatim*. It is not, quite: the strip is
`refused:${outcome#merge_refused:}`, while the canonical recorded outcome carries a space —
`catch-up-claim.sh` writes `merge_refused: ${gate_reason}` and `workaholic:drive` §6 states the
outcome as `merge_refused: <word>`. So the reader emits `refused: session_type_cannot_merge`,
with a space its documented shape does not have.

Observed by running it against a fixture carrying the canonical form; not a hypothesis. Nothing
is broken by it today — the reconciliation compares against `taken` and the report is still
readable — which is why this is a ticket rather than a fix taken opportunistically inside another
ticket's scope. What it costs is that a consumer matching the documented `refused:<word>` shape
finds a string no reader prints, which is the class of drift this repository single-sources to
avoid.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/act-effect.sh` — the strip, and the header stating the
  shape it does not emit.
- `plugins/workaholic/skills/story/scripts/record-merge-outcome.sh` — the one writer of the
  recorded outcome, whose format the strip must match.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — a writer of the spaced form.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the effect vocabulary is defined.

## Implementation Steps

1. Establish which forms are actually written, from the writers rather than from the documents:
   both `merge_refused:<word>` and `merge_refused: <word>` appear in this tree.
2. Make the reader tolerate both and emit exactly one — the documented `refused:<word>` — without
   changing any writer or any word.
3. Add a hermetic row per written form asserting the emitted shape, so the two cannot drift again.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `act-effect.sh delivery` emits `refused:<word>` for every recorded form a writer produces.
- No refusal word is renamed, dropped or normalised beyond the separator.
- The writers are untouched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a row per written form.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- Fix the reader, not the writers: `merge_refused: <word>` is `workaholic:drive` §6's own
  documented outcome format and is written into branch stories that already exist.
- This is cosmetic today. If it is judged not worth doing, the honest alternative is to correct
  `act-effect.sh`'s header to document what it emits — not to leave the two disagreeing.

## Final Report

Development completed as planned.

`act-effect.sh`'s delivery arm now absorbs the separator and carries the word untouched: both
`merge_refused: <word>` (what every current writer records — `retry-undelivered.sh`,
`catch-up-claim.sh`, `settle-stranded-publication.sh`) and `merge_refused:<word>` (older records
and the drill's own fixture) emit the header's documented `refused:<word>`. No writer moved, no
refusal word was renamed, and `unstated`, `pending` and `unreadable` are exactly what they were.
Seventeen hermetic rows in `test-workflow-scripts.mjs` pin one row per written form, one per
carried word, and a shape assertion over every delivery answer.

### Discovered Insights

- **Insight**: The reader's own header was the specification the code failed, and nothing
  compared the two — `reference/claims.md` line 592 documents `refused:<word>` and the strip
  produced something else for a year of records.
  **Context**: Where a script's header is the contract, a shape assertion over the emitted value
  is worth more than a row per case: the row-per-case rows would all have been written against
  the buggy output by anyone reading the code rather than the header.

- **Insight**: `--claims FILE` makes this reader testable with no repository at all — the claim
  oracle's output is the only input the delivery arm has.
  **Context**: The hand-back flag was added for an N+1 cost, and it doubles as the seam that
  keeps a reader composing `list-claims.sh` hermetic in the suite.
