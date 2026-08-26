---
created_at: 2026-08-26T04:20:21+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: attribute-an-inbound-ask-to-the-direction-it-answers
merge_policy:
verification_handoff: 
---

# Walk the sweep's ask in the chain test

## Overview

PROPOSED. `testCarryChainIsProvable` walks ask → reader → scaffold → floor for the ask
shape `open-proposal.sh` writes, and that test is what makes `attributed-work.sh`'s
`no_citing_artifacts` mean *nothing has answered this direction yet* rather than *the link
may simply have been dropped*. The guarantee is bounded to work the loop emitted from an
ask whose refs resolved — and the sweep is the loop's own writer, so an ask it filed
belongs inside that bound and today sits outside it.

This ticket extends the same test to the sweep's ask shape and to `/fb`'s in-repo shape,
and writes down what the extended bound does and does not cover, so the reading is not
over-claimed.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — `testCarryChainIsProvable`, the chain this extends
  rather than duplicates
- `plugins/workaholic/skills/strategy/SKILL.md` — where `no_citing_artifacts`'s meaning and
  its limits are stated
- `plugins/workaholic/skills/propose/SKILL.md` — the not-a-refusal sentence that rests on
  this proof
- `plugins/workaholic/skills/specificate/SKILL.md` — *What the three together buy*
- `CLAUDE.md` — the `/specificate`, `/propose` and Strategy paragraphs that state the bound

## Implementation Steps

1. Extend `testCarryChainIsProvable` with the sweep's ask shape — the header block
   `file-inbound-ask.sh` composes, `slack-ref:`/`slack-link:` lines included — and walk the
   same four links: the reader recovers the refs, the scaffold carries them, the floor
   passes, and the same ask published without them is refused.
2. Add the `/fb` in-repo ask shape to the same walk: one more fixture, the same four links.
3. Add the negative that matters: a swept ask with **no** `feedback:` line reads back
   `line_found: false`, emits work carrying nothing, and the floor passes with
   `checked: 0` — an unattributed ask is a real pass, never a failure.
4. State the extended bound in the documents above: it now covers work the loop emitted
   from an ask filed by `/propose`, by the sweep, or by `/fb`'s in-repo path whose refs
   resolved — and **not** work a run never emitted, an ask judged to answer no direction, a
   ref that did not resolve, or an artifact written by hand outside `/specificate`.
5. Rebuild `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The chain test walks the sweep's ask and `/fb`'s in-repo ask, and fails when the ref is
  dropped from either
- An unattributed swept ask is proved to pass the floor with `checked: 0`
- The bound and its limits are stated in the strategy, propose and specificate skills and
  in `CLAUDE.md`, in the same change

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `attributed-work.sh` is **not** changed: it stays the single attribution reader and its
  `empty_reason` vocabulary is unchanged — adding a state to describe a hole the floor
  closes would be a second mechanism for one guarantee
- Documentation and code land in the same commit

## Considerations

- The test is **extended**, not copied. A second near-identical test function drifts from
  the first within two changes; the fixtures differ only in the ask's header block.
- Stating the limits is half the deliverable. A bound that reads as exhaustive is worse
  than one that names what it misses, and the previous mission's own record says so.
