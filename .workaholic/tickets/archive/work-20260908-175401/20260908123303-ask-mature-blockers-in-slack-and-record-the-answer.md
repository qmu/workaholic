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

# Ask mature blockers in Slack and record the answer

## Overview

Route a mature decision dependency to the responsible person as one decision-ready Slack question and record the answer through the loop's existing answer path.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/` — question selection, deduplication, and addressed rendering.
- `plugins/workaholic/skills/notify/` — exact thread lookup and delivery contract.
- `plugins/workaholic/skills/feedback/` — answer capture and attribution.

## Implementation Steps

1. Map mature blocker identity to the existing subject-key and responsible-person resolution.
2. Render one concise question containing the decision, premises, alternatives, and effect of each answer.
3. Reuse exact thread lookup and answer recording rather than creating a parallel inbox.
4. Test one-time delivery, unanswered persistence, and answer capture.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A mature blocker reaches the responsible person once and is answerable from the Slack message itself.
- A reply is captured against the exact blocker and strategy.

**Verification method** — the commands/tests/probes that prove them:

- Run notification and moderation tests with found-thread, new-root, and reply cases.

**Gate** — what must pass before approval:

- No fuzzy routing, duplicate question root, or unaddressed blocker is accepted.

## Considerations

Delivery remains non-load-bearing, but a failed delivery must stay observable so it cannot masquerade as a pending human decision.

## Final Report

Development completed as planned.

The route a mature blocker takes to its person already existed — `direction-health` asks the
strategy's assignee through `ask-question.sh`'s asked-once ledger, `workaholic:notify`'s exact
thread lookup carries it, `record-answer.sh` records the reply and `file-inbound-ask.sh` turns an
ask into an `[FB]` issue. What was missing was the judgment **before** the ask, so the step now
reads `decision-maturity.sh` for its four attribution readings and asks only an `ask_now` one.
A withheld question is named in the log-facing summary with its verdict and missing premise,
spends no ledger line, and is re-derived every tick — the observable route to resolution, with no
store, no cursor and no flag. No parallel inbox was created and no post shape moved.

### Discovered Insights

- **Insight**: `survey-strategies.sh`'s header documents an `observing` refusal — *the operator
  DECLARED this direction 観察中, so the loop is reactive only* — that its refusal ladder no
  longer emits. `commands/propose.md` states the current rule (`観察中` permits observation work
  and guides the hypothesis), and the survey's own sort comment still asserts the retired one
  (*観察中 never reaches this sort at all — it is refused `observing` one step above*).
  **Context**: a rung keyed on that word would have been dead code, and the first draft of the
  maturity ladder was. The reader tests the **declared stage** off the row instead, which is
  correct whether or not any other script refuses on it. The stale prose is filed as its own
  ticket.

- **Insight**: `stage_declared` is the field that makes a stage safe to act on. `absent means
  進行中` is the right reading everywhere and the wrong thing to *act on* — the same distinction
  `step-direction-health.sh` already draws when it refuses to quote a stage nobody declared.
  **Context**: a repository that has not adopted the vocabulary keeps every question it had,
  byte for byte; the gate arrives only once an operator has actually declared a phase.

- **Insight**: two readings of one survey can disagree, and the cheap fix is a hand-back rather
  than a second call. `direction-state.sh --emit-survey <file>` writes the survey it already made
  to a path the caller names, so the maturity verdict is judged against exactly the rows the
  lifecycle states came from, at no extra network read.
  **Context**: `survey-strategies.sh` makes one network call (`list-open-proposals.sh`) and
  refuses the whole tick rather than proceed without it, so a per-subject re-survey would have
  multiplied that cost by the number of directions and introduced a second source of truth for
  the same fact — the drift this step already refuses for the residue and the leaving.
