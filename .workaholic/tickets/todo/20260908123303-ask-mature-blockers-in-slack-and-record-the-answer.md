---
created_at: 2026-09-08T12:33:03+09:00
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
