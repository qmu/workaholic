---
created_at: 2026-08-27T20:21:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Write the asking half into the documents

## Overview

PROPOSED. The handoff axis is documented thoroughly on the routing side and says nothing about
the asking side, because until this mission there was none. State in one place per document
that `awaiting_verification` is now read by a question surface, what that question says, and
what it still refuses to do — so the next reader does not re-derive the design or, worse,
"fix" the omission by making the consumer act.

This repository treats outdated documentation as a defect, so this ticket lands with the work
rather than after it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` — the docs move in the same change as the behaviour

## Key Files

- `CLAUDE.md` — the `/moderate` row (the step count and the enumerated steps) and the claim
  protocol's `awaiting_verification` paragraph, which currently ends at *"`claim.sh resume`
  refuses it by its own name"*.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step list and the per-step contract.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the ordered step contract.
- `plugins/workaholic/skills/drive/reference/claims.md` — the `awaiting_verification` row in
  *Proofs and judgements*: name the reporting consumer, and keep the licence unchanged.
- `plugins/workaholic/skills/drive/SKILL.md` — §1's claim paragraph and §7's report contract,
  where the exclusion reason's meaning is stated.

## Implementation Steps

1. Update `/moderate`'s step count and enumerate `handoff-units` beside `undelivered-units`,
   in the same shape the neighbouring steps use: which reading it consumes, **whose** question
   it is, that the running identity is never consulted, and that it reads `list-claims.sh` and
   never `plan-units.sh`.
2. Extend the claim protocol's `awaiting_verification` paragraph with the asking half: the
   verdict now reaches the claim holder as one question naming the declared reason, and
   `stalled-units` no longer asks the wrong question about the same unit.
3. In `claims.md`, name `step-handoff-units.sh` as an enumerated **reporting** consumer of the
   verdict. Do not restate the classification or add a second table — the row already says a
   consumer may only report or ask.
4. State plainly what it still refuses to do: never clears a handoff, never retries a
   verification, never merges the pull request, never withdraws or declares the field, touches
   no claim, and writes nothing but its own tick-log line.
5. Record the two-writer facts that did **not** move: `verification-handoff.sh` is still the
   one reader of the field, `/specificate` and `/ticket` are still its only writers, a run
   never declares it for its own unit, and the verdict still does not forbid `ok`.
6. Run `doc-drift.sh` and confirm nothing else in the tree still describes the asking side as
   absent.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every listed document names the new step, what it asks, and what it refuses
- `/moderate`'s step count matches `run.sh`'s `STEPS`
- No document still says `awaiting_verification` is read nowhere outside `drive/`
- The classification and the writer set are restated nowhere a second time

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `grep -rn "awaiting_verification" plugins/ CLAUDE.md` — every hit reads correctly
- `sh plugins/workaholic/skills/story/scripts/doc-drift.sh`

**Gate** — what must pass before approval:

- The suite passes, the step count is consistent, and drift is clean

## Considerations

- Keep it to one statement per document. The temptation with a well-reasoned change is to
  restate the whole argument in four places; the reasoning belongs in the step's own header and
  the mission record, and a fifth copy is a fifth thing to keep in sync.
- The ask's rival — one unified "what the loop is blocked on" report over the four vocabularies
  — was refused with its reason. Record that refusal once, where a future reader would
  otherwise propose it again.
