---
created_at: 2026-08-11T00:12:26+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: give-propose-and-ticket-a-diagnosis-first-discovery-pass
merge_policy:
---

# Add a diagnosis-first rule to /ticket and /propose

## Overview

Issue qmu/workaholic#374 (feedback `20260811001004`) observes that neither `/ticket` nor
`/propose` measures a failing mechanism before designing a fix: discovery reads, nothing
probes the live surface the failure lives on. This ticket adds a diagnosis-first rule to
both — an ask reporting a failure of an existing mechanism yields a ticket whose step 1
is "reproduce and localize the failure" (measure the live surface), with the reporter's
proposed fix recorded as a hypothesis in Considerations, never adopted directly as the
design. The reframed thread-key ticket (commits `52681f0`/`3172a65`, which measured the
lookup's search-scope root cause live before rewriting its steps) is a worked example of
what this rule demands.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/discover/SKILL.md` — candidate single source for the rule's
  statement, since both `/ticket`'s and `/propose`'s discovery steps already read it
  (avoids restating the rule in two skills)
- `plugins/workaholic/skills/create-ticket/SKILL.md` §5 (Write Ticket(s)) — where
  `/ticket`'s Implementation Steps get authored; the rule applies here
- `plugins/workaholic/skills/propose/reference/workflow.md` step 8 (Emit the tickets) —
  where `/propose`'s scaffolded ticket Implementation Steps get authored; the rule
  applies here too
- `plugins/workaholic/skills/propose/SKILL.md` — *The judgment bar*, to note the rule
- `CLAUDE.md`'s `/ticket` and `/propose` rows — update if the workflow description
  changes materially

## Implementation Steps

1. State the diagnosis-first rule once, in the place both commands' discovery step
   already reads (`workaholic:discover`, per Key Files) rather than restating it in two
   skills — following this repo's existing "state once, refer, never restate" pattern
   (e.g. `rules/interaction.md` for `AskUserQuestion` necessity).
2. Apply it in `/ticket`: when the request is classified as a failure report about an
   existing mechanism (not a new-feature ask), the written ticket's Implementation Steps
   begin with reproducing and localizing the failure, and any reporter-proposed fix is
   recorded under Considerations as a hypothesis rather than folded into the steps.
3. Apply the same rule at `/propose`'s step 8 (Emit the tickets).
4. Update `CLAUDE.md`'s `/ticket` and `/propose` rows if their description changes.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A failure-report ask routed through `/ticket` produces a ticket whose Implementation
  Steps begin with reproducing/localizing the failure.
- The same holds for a failure-report ask routed through `/propose`.
- A reporter's proposed mechanism, when present, is captured under Considerations as a
  hypothesis, never written into the Implementation Steps as the adopted design.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` pass.
- A manual or hermetic check: point `/ticket` and `/propose` at a synthetic
  failure-report ask and confirm the resulting ticket's step 1 is diagnostic, not the
  reporter's proposed fix.

**Gate** — what must pass before approval:

- The reviewer has confirmed the classification of "failure report about an existing
  mechanism" versus "new-feature ask" fails toward existing behavior on ambiguity.

## Considerations

- Where exactly the rule is stated once is itself an unrecommendable-adjacent choice
  worth the implementer's explicit attention, not this proposal's assumption.
- Distinguishing a failure report from a new-feature ask is a judgment call; a false
  positive (treating an ordinary feature request as diagnosis-first) should degrade to
  the existing behavior rather than block.
