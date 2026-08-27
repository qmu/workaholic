---
created_at: 2026-08-27T05:22:41+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Pin the proof judgement split with a hermetic test

## Overview

PROPOSED. Ticket 1 writes the proof/judgement table, and a table is prose: nothing stops a
later change from acting on a judgement verdict, or from adding a verdict word to
`lib/claims.sh` that the table never classifies. This ticket makes the split a fact a change
can **lose** rather than a claim in prose — the same standing this repository gave the
`/specificate` carry chain when it pinned ask → reader → scaffold → floor.

`scripts/test-workflow-scripts.mjs` fails if a consumer acts on a judgement verdict, or if the
table and its two consumers disagree about a word.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the pin lands here.
- `plugins/workaholic/skills/drive/reference/claims.md` — the table the test reads as the source.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the verdict word set the table is
  checked against.
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — consumer 1 (ticket 4).
- The `/implement` delivery retry — consumer 2 (ticket 2).

## Implementation Steps

1. Read the carry-chain pin in `test-workflow-scripts.mjs` for the shape: it walks the real
   seams rather than asserting a restated copy, which is what makes it able to fail.
2. Assert the table covers `lib/claims.sh`'s verdict word set exactly — a word emitted and not
   classified fails, and a word classified and never emitted fails too.
3. Assert `superseded` and `report_undelivered` are the only `proof` rows.
4. Assert each of the two consumers gates on a **proof** word: `retire-claim.sh` refuses every
   non-`superseded` verdict, and the delivery retry runs only on `report_undelivered`.
5. Prove the test can fail: change a consumer's gate to a judgement word in a scratch copy and
   confirm the suite fails. State that check in the test's own comment.
6. Keep it hermetic: no network, no `gh`, no working-tree writes — the suite's standing rules.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `node scripts/test-workflow-scripts.mjs` fails when a consumer gates on a judgement verdict.
- It fails when the table and `lib/claims.sh` disagree about the word set in either direction.
- It passes over the healthy tree.
- It makes no network call and writes nothing into the working tree.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Introduce each of the two failures in a scratch copy and confirm the suite fails on each.

**Gate** — what must pass before approval:

- Both failure modes are demonstrated, not just asserted.

## Considerations

- A test that reads a restated copy of the table proves only that the copy matches itself.
  Read the table and the consumers' actual gates.
- If reading a shell script's gate from a Node test proves too brittle, the honest alternative
  is a machine-readable classification `lib/claims.sh` emits — but that is the second
  derivation ticket 1 weighed and set aside, so reopening it is a decision to record in the
  ticket's own Considerations, not a silent change of plan.

## Final Report

Development completed as planned.

`testProofJudgementSplit` reads the real seams rather than a restated copy, which is what the
Considerations required: the word set comes out of `lib/claims.sh`'s own emissions, the
classification out of the table's own rows, and each consumer's gate out of that consumer's own
source. A test carrying its own list of words would prove only that the list matches itself.

The set equality is asserted in **both** directions. A word emitted and not classified leaves a
consumer with no rule; a word classified and never emitted is a rule about nothing, and that is
how a table starts lying about the code it describes.

The machine-readable classifier the Considerations named as the fallback was **not** needed and
is not introduced: reading a shell gate from a Node test turned out to be neither brittle nor
indirect, because each gate is a single literal comparison on one line. Ticket 1's decision to
keep the classification as prose over a word the library already emits therefore stands
unchanged.

All three failure modes were demonstrated, not asserted:

- `retire-claim.sh`'s gate changed to `queue_drained` → `retire-claim.sh gates on a proof` red.
- the `parked_with_pr` row deleted → `every verdict word the library emits is classified` red.
- an invented word added to the table → `the table classifies no word the library never emits` red.

Each turned exactly one row red and nothing else; the tree was restored after each and the suite
re-run green (3911 passed, 0 failed).

### Discovered Insights

- **Insight**: The library emits its vocabulary in three different shapes, and the test has to
  match each rather than one.
  **Context**: The resumability verdict is `_cs_reason=<word>`; the unit resolution is
  `printf '<word>\n'`; the merged lookup forwards two of its words through a `case` pattern
  (`merged|not_merged)`) and prints the third with no trailing newline. A single pattern silently
  missed the third family, and the test caught it as three phantom rows — which is exactly the
  direction of the check that would otherwise have looked redundant.

- **Insight**: `stale` is allowed by name, never by a wildcard.
  **Context**: It is the one classified row that is a boolean field rather than an emitted word.
  Exempting it with a general escape hatch would let a second unemitted row slip in behind it, so
  the test names it and separately asserts `_cs_stale=true` is still set — if the flag ever goes
  away, the row stops describing anything and the test says so.

- **Insight**: Naming the two consumers explicitly beats discovering them.
  **Context**: A glob over the scripts directory would quietly pass when a third consumer is
  added with no gate at all — the failure the pin exists to prevent. The explicit list fails
  loudly when a named consumer loses its gate, and adding a consumer means adding a row here,
  which is the reminder rather than the obstacle.
