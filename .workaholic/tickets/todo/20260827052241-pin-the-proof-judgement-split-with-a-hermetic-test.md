---
created_at: 2026-08-27T05:22:41+00:00
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
