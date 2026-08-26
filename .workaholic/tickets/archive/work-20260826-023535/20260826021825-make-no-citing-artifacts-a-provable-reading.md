---
created_at: 2026-08-26T02:18:25+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826021825-floor-the-carry-at-the-publish-seam.md
mission: prove-the-loop-s-closing-link
merge_policy:
verification_handoff: 
---

# Make no_citing_artifacts a provable reading

## Overview

`attributed-work.sh` answers `no_citing_artifacts` for two different situations that a
reader cannot tell apart: a direction nothing has answered yet, and a direction whose
answer was published with the link dropped. `workaholic:propose` treats the first as
explicitly *not* a refusal — "exactly when a proposal is most wanted" — so the second is
invisible and self-perpetuating.

The previous three tickets close the hole at the writing end. What remains is to make the
resulting guarantee **provable rather than asserted**: after the floor, a proposal that
emitted work from an ask with resolvable refs cannot have lost them, so
`no_citing_artifacts` means *nothing has answered this direction yet* — and that must be
pinned by a test and stated where the loop is described, or the next reader has only prose
to trust.

## Policies

- `workaholic:implementation` / `policies/observability.md` — two states that mean different
  things must not render alike
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the end-to-end hermetic case that pins the chain
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the one attribution
  reader; read its `empty_reason` derivation before changing anything about it
- `plugins/workaholic/skills/propose/SKILL.md` — states that `no_citing_artifacts` is not a
  refusal; that statement now rests on a proof and should say so
- `plugins/workaholic/skills/specificate/SKILL.md` — *Carry the ask's own feedback refs
  forward*, the section the guarantee belongs to
- `CLAUDE.md` — the `.workaholic/` runtime conventions paragraph on attribution, and the
  `/specificate` and `/propose` rows

## Implementation Steps

1. Write the hermetic end-to-end case: an ask body carrying a resolvable ref → the reader
   returns it → a scaffolded mission carrying it → `check-carry-floor.sh` passes; and the
   same chain with the ref omitted from the mission → the floor refuses. This is what turns
   the guarantee into a fact a test can lose.
2. Add the negative case that matters: a strategy with `feedback:` refs and **no** citing
   artifact still answers `no_citing_artifacts`, unchanged — the reading is preserved, only
   its meaning is now unambiguous.
3. State the guarantee where each reader meets it: `specificate/SKILL.md` (the carry section),
   `propose/SKILL.md` (beside the "not a refusal" sentence), and `CLAUDE.md`. Say what the
   guarantee does **not** cover, so it is not over-read — a proposal a run never emitted, an
   ask that named no refs, and an artifact written by hand outside `/specificate` are all
   still uncited for ordinary reasons.
4. **Change `attributed-work.sh` only if the previous steps prove a change is needed.** It is
   the single attribution reader and the transitive, lossy shape is a written decision; adding
   a state to it to describe a hole the floor has already closed would be a second mechanism
   for one guarantee. If the tickets above hold, this ticket is a test and three documents.
5. Regenerate `outputs/` and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A hermetic test walks ask → reader → scaffold → floor and fails when the ref is dropped
- A strategy with refs and no citing artifact still reports `no_citing_artifacts`
- `specificate/SKILL.md`, `propose/SKILL.md` and `CLAUDE.md` state the guarantee and its limits
- No artifact gained a field; the retired `strategy:` relation did not return

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `git grep -n "strategy:" plugins/workaholic/skills/strategy` — confirms the retired relation
  did not return

**Gate** — what must pass before approval:

- The chain test fails on a dropped ref, and the three documents agree

## Considerations

- The strongest temptation here is to add an `empty_reason` such as "carried but nothing
  merged yet". Resist it unless the floor leaves a real gap: the ask's own fourth point says
  `attributed-work.sh` stays the one attribution reader and no artifact gains a field.
- The guarantee is bounded by what the floor can see — work published by `/specificate` from
  an ask carrying resolvable refs. Hand-written missions and asks with no refs are outside it,
  and the documents must say so rather than implying attribution is now exhaustive.

## Final Report

Development completed as planned, and step 4's condition came back negative:
`attributed-work.sh` is **unchanged**. The previous three tickets close the hole at the
writing end, so adding a state to the single attribution reader would have been a second
mechanism for one guarantee — the ticket's own Considerations say to resist exactly that, and
nothing measured here argued for it. A test asserts its `empty_reason` vocabulary is
unchanged, so a later change to it is a deliberate act rather than a drift.

What shipped is the end-to-end hermetic case — ask body → `read-ask-feedback-refs.sh` →
`scaffold-draft.sh` → `check-carry-floor.sh`, passing when the ref rides and refusing when it
is dropped, with `attributed-work.sh` then attributing the carried mission and not the
dropped one — plus the preserved negative (a strategy with refs and nothing citing them still
answers `no_citing_artifacts`, exit 0), and the guarantee stated with its limits in
`specificate/SKILL.md`, `propose/SKILL.md` and `CLAUDE.md` (twice: the attribution paragraph
and the `/propose` row).

### Discovered Insights

- **Insight**: The chain test's value is in the *negative* half — the same chain with the ref
  omitted from the mission.
  **Context**: The passing half only shows the scripts agree today. The failing half is what
  makes the guarantee losable: a future change that reopens the hole fails here instead of
  surfacing months later as an ambiguous `no_citing_artifacts`.
- **Insight**: Stating the limits was the load-bearing half of the documentation change.
  **Context**: The guarantee is bounded to work the loop itself emitted from an ask whose
  refs resolved. Written without that clause it reads as "attribution is now exhaustive",
  which is a stronger and false claim about a reader whose lossiness is a written decision.
