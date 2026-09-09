---
created_at: 2026-09-08T12:33:03+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-quiescent-blockers-into-mature-decisions-and-resume-work
merge_policy:
verification_handoff: 
---

# Judge whether a human decision is mature enough to block

## Overview

Introduce the decision-maturity judgment before a loop observation can become a human gate. The judgment must name missing business, design, data, or operational premises and select defer, retire, prerequisite planning, or ask-now.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/` — derive and render decision-ready blockers.
- `plugins/workaholic/skills/propose/` — expose why an evolutionary move cannot proceed.
- `plugins/workaholic/rules/workaholic.md` — keep the maturity and origination responsibilities in one model.

## Implementation Steps

1. Trace how `quiescent`, `no_evolutionary_move`, and existing decision questions are currently derived and deduplicated.
2. Define one maturity verdict with explicit outcomes for ask-now, defer, retire, and prerequisite planning.
3. Carry the verdict and its evidence into moderation without turning every observation into a gate.
4. Cover mature and immature examples in the routine suites.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Premature or meaningless questions cannot block a strategy.
- Each deferred question reports the premise or planning work it lacks.

**Verification method** — the commands/tests/probes that prove them:

- Run the propose and moderate script suites with fixtures for each verdict.

**Gate** — what must pass before approval:

- Existing quiescent and no-move readings remain observations and all maturity cases are deterministic in tests.

## Considerations

The maturity decision is a model judgment; its evidence and outcome must remain visible and arguable rather than hidden in a score.

## Final Report

Development completed as planned.

The maturity judgment is one reader, `moderate/scripts/decision-maturity.sh`, and one rule,
`rules/workaholic.md` *When a Human Decision May Block the Loop* — stated beside the origination
rule it forms a model with, cited by every consumer and restated by none. The verdict is a ladder
over fields `propose/scripts/survey-strategies.sh` already emits (`retire` → `prerequisite` →
`defer` → `ask_now`), with `premises[]` carrying each premise, whether it held and the evidence
that decided it, so the outcome stays arguable rather than hidden in a score. The reader gates
nothing by itself and writes nothing; a degraded read answers `readable: false` with no verdict at
all.

### Discovered Insights

- **Insight**: `survey-strategies.sh` puts the states this judgment is about into `refused[]`,
  not `eligible[]` — `not_active`, `observing`, `no_feedback_refs`, `work_waiting` and
  `open_proposal` are refusal words by construction. A reader that walked only `eligible[]`
  would find nothing for exactly the directions it is asked about.
  **Context**: `refused[]` rows carry `dormant`, `quiescent`, `residue`, `stage`, `assignees`
  and the waiting grains for this reason, and deliberately carry no `feedback_refs` — the
  refusal word is the reading. Any later consumer of a direction's state must search both
  lists and project an empty `reason` onto the eligible one.

- **Insight**: since 2026-09-03 `step-direction-health.sh` asks **one question per reading**
  naming every direction in it, so a question key is `direction-<reading>:<slug>+<slug>` and
  `question-state.sh --key direction-<reading>:<slug>` answers `never_asked` for a direction
  that was asked about inside a group.
  **Context**: the key's own slug list is the only record of that membership, so anything
  asking *was this direction asked about* must match the slug against the key rather than
  reconstruct the key. The grouping was introduced to stop five near-identical questions in
  twenty-four seconds, and it silently changed what a per-slug ledger lookup means.

- **Insight**: `dormant` deliberately does **not** carry the degraded-residue term that
  `quiescent` does, and the asymmetry is load-bearing: *claiming a direction has arrived on a
  blind read sends the operator to close it; every other reading only asks them to look.*
  **Context**: the obvious shape for a maturity ladder is a `residue_unreadable` rung, and it
  would silently overturn that decision for `dormant`. This reader adds no completeness gate of
  its own, and its header and the suite both say so.
