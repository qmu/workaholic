---
created_at: 2026-08-22T22:52:04+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: read-a-strategy-s-pace-against-its-date
merge_policy:
verification_handoff: 
---

# Report a strategy's pace against its remaining days

## Overview

`survey-strategies.sh` already reads everything this needs and throws the combination away. It
computes `days_to_target` and uses it **only to sort** and to refuse `past_target_date`. It reads
`attributed-work.sh`, which returns `landed[]` — what has actually merged against the direction —
and uses it **only** to decide `no_citing_artifacts` and `work_waiting`.

Nowhere are the two put together. So the survey can say *this direction has seven days left* and
*this direction has nineteen landed artifacts* and never form the sentence a person forms
instantly on hearing both: **is it going to arrive?**

This ticket adds only the reading. What the tick does with it is the sibling's subject, so this
one lands and changes no observable behaviour.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — computes `days_to_target`,
  calls the attribution reader, and emits the per-strategy rows. The reading lands here.
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the one attribution reader;
  its header states that attribution is **transitive and lossy** and that every consumer must
  report what it could not attribute. That constraint binds this ticket.
- `plugins/workaholic/skills/propose/SKILL.md` — the gate list and the window's own definition
  (`landed[]` is *the evidence the judgment is made against*, not a changelog).
- `plugins/workaholic/skills/strategy/SKILL.md` — what a `target_date` means and who may move it.

## Implementation Steps

1. **Reproduce before designing.** Run the survey against the measured shape — a strategy seven
   days from its date whose landed artifacts are all of one kind — and confirm from the output
   that nothing in it distinguishes that from a direction on course.
2. **Localize.** Confirm `days_to_target` and the attribution read already meet in one function,
   so the reading composes rather than adding a second walk of the tree.
3. Emit a **pace** reading per surveyed strategy. It must be derived from what already exists —
   `landed[]` within the window and `days_to_target` — and must not require a new field on any
   artifact. The 2026-08-17 no-new-field ruling stands.
4. **Make it honest about what it cannot see.** Attribution is lossy by its own header, so a pace
   reading is evidence, never a verdict: emit `unknown` when the attribution was degraded or the
   strategy has no `target_date`, and never let `unknown` collapse into "on course" or "late".
5. **Do not judge quality here.** Whether nineteen pages advance a build aim is
   `describing_move`'s question and is already answered elsewhere; this reading is about rate and
   remaining time, and conflating the two would put one judgement in two places.
6. Change no observable behaviour: the gates, the ordering and the refusals all stay as they are.
7. Update `propose/SKILL.md` in the same commit to state what the reading is and what it is not.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every surveyed strategy carries a pace reading derived from `landed[]` and `days_to_target`.
- A degraded attribution read, or an absent `target_date`, yields `unknown`, distinct from both
  other answers.
- No new field is written to any artifact, and `attributed-work.sh` stays the one attribution
  reader.
- The gates, the ordering and the refusals are byte-for-byte unchanged in behaviour.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`
- Fixtures for on-course, late, and unreadable-attribution strategies asserting the three answers.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the propose drill are clean.

## Considerations

- Resist making pace a number that looks precise. `landed[]` is lossy and a direction's work is
  not uniform, so a ratio would imply an accuracy the input cannot support; a small named set of
  answers is honest and is what the sibling ticket can act on.
- A strategy with no `target_date` is not late — it is undated, and the strategy artifact requires
  a date, so this case means a malformed record and should read as `unknown`.
