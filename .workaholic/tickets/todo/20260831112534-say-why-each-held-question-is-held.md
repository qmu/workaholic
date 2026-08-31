---
created_at: 2026-08-31T11:25:34+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-check-in-queue-is-stuck-and-bound-the-hold
merge_policy:
verification_handoff: 
---

# Say why each held question is held

## Overview

`all_held` is one token over four different refusals — `quiet_hours`, `off_day`,
`tick_cap` and `day_cap` — so the operator is told that everything is held and never why,
and the four call for different acts (wait until morning, wait until Monday, wait an
hour, the budget is spent). The gate already answers per candidate; the step asks it once
with a tick-unique key and keeps only the aggregate.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the held set and
  the probe.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate. Read and
  called, **never modified**: no key, cap or hold moves.


## Implementation Steps

1. Ask the gate **per held candidate** instead of once with a tick-unique key, so each
   entry carries the gate's own refusal word verbatim. The probe already writes nothing
   (recording an ask is `--record-ask`'s separate mode), so the ledger stays untouched.
2. Carry the word on each entry of `held` as its own field, leaving the entry's key and
   the set's **order** exactly as the drain ordering produces them.
3. Keep `all_held` as the step's `reason`: it is still the honest summary word, and this
   adds the detail beneath it rather than replacing it.
4. Report the word verbatim — a normalised or re-worded refusal sends a reader to a
   string no script printed.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every entry of `held` carries the gate's own refusal word, verbatim.
- A tick held by quiet hours and one held by a spent day cap are distinguishable from the
  step's output alone.
- `ask-question.sh` is byte-identical, the ledger is unwritten by the probe, and the
  questions asked, the caps and the holds are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery`

**Gate** — what must pass before approval:

- No second gate, no second ledger, and no field on any artifact.


## Considerations

- Two of the four words (`quiet_hours`, `off_day`) are tick-wide and will be identical on
  every entry; that is the true answer and is reported rather than collapsed, because the
  cap words are not tick-wide and one shape must cover both.
- The per-candidate probe costs one local script call per held key. The held set is what
  the drain already orders, so it is bounded by the same set.

