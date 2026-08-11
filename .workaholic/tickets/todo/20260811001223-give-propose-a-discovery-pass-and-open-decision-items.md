---
created_at: 2026-08-11T00:12:23+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: give-propose-and-ticket-a-diagnosis-first-discovery-pass
merge_policy:
---

# Give /propose a discovery pass and open_decision items

## Overview

Issue qmu/workaholic#374 (feedback `20260811001004`) observes that `/propose` reads only
missions/queue/commits (`survey-state.sh`) as constraints and never runs anything
comparable to `/ticket`'s history/source/policy discovery (§2 of `create-ticket/SKILL.md`)
before scaffolding a mission or ticket — so a store-location decision that `/ticket`'s
§4b would have interrogated a human on instead got silently inherited from the
reporter's framing. This ticket gives `/propose` a discovery pass (history at minimum)
before scaffolding, and a convention for recording a genuinely unrecommendable fork as
an explicit `open_decision` item the implementing tick must stop at, instead of choosing
for the reporter.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/reference/workflow.md` — the ordered step-by-step
  contract; the discovery pass is inserted between step 4 (read constraints) and step 6
  (judge and decide the form)
- `plugins/workaholic/skills/propose/SKILL.md` — *The judgment bar*, which currently
  lists feedback/missions/queue/commits as the only inputs
- `plugins/workaholic/skills/discover/` — the existing history/source/policy discovery
  skill `/ticket` already uses; reuse its history mode rather than duplicating it
- `plugins/workaholic/skills/create-ticket/SKILL.md` §2/§4b — the `/ticket` precedent
  (parallel discovery, then interrogate only on unrecommendable forks) this ticket ports
- `CLAUDE.md`'s `/propose` command row — update if the workflow description changes materially

## Implementation Steps

1. **Reproduce and localize first**: read the #360 chain's own history (`52681f0`,
   `3172a65`, and the feedback records they cite) to confirm precisely which decision
   `/propose` inherited unexamined, before designing the discovery step's shape.
2. Add a discovery step to `/propose`'s Workflow (`reference/workflow.md`), run before
   scaffolding: for an ask that names an existing mechanism or builds on a prior
   decision, run at least a history-mode pass (`workaholic:discover`) over that
   mechanism. Decide, as an `open_decision` in this ticket if genuinely unrecommendable,
   whether this runs inline in the `/propose` session or as a spawned
   `general-purpose` subagent — the Architecture Policy's nesting rules govern which is
   permitted for a skill invoked as `/propose`.
3. Define the `open_decision` convention: when discovery surfaces a fork `/ticket`'s
   §4b would interrogate a human on, the proposal records it as an explicit item (e.g. a
   ticket `## Open Decisions` section or a frontmatter key) the driving tick must stop at
   — never silently resolved by the proposing session.
4. Update `propose/SKILL.md`'s judgment bar to name discovery as an input.
5. Update `CLAUDE.md`'s `/propose` row and any other doc describing `/propose`'s inputs.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/propose`'s workflow runs a discovery step, at minimum history-mode, before
  scaffolding a mission or ticket.
- A fork discovery surfaces as genuinely unrecommendable is recorded as an explicit
  `open_decision` item on the emitted artifact rather than silently resolved.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` pass.
- A hermetic or manual re-run of `/propose` against a reconstruction of the #360
  scenario, confirming the store-location fork is now surfaced as an `open_decision`
  rather than adopted silently.

**Gate** — what must pass before approval:

- The reviewer has confirmed the discovery step is bounded (does not regress toward the
  retired sweep-the-backlog design) and weighed the subagent-vs-inline fork this ticket
  leaves open.

## Considerations

- `/propose` is a single unattended session with no command-level fan-out today; adding
  subagent-based discovery may need the command layer, not the skill, to spawn it
  (Architecture Policy, One-Level Fan-Out) — an unrecommendable fork for the
  implementing tick to decide, not this proposal.
- Keep discovery scoped to the ask already in hand — it reads context for that ask, it
  must not become a second sweep of the backlog (the retired `[Propose Batch]` design).
