---
created_at: 2026-08-31T11:25:34+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-check-in-queue-is-stuck-and-bound-the-hold
merge_policy:
verification_handoff: 
---

# State the hold's bound where the voice is defined

## Overview

This repository's own rule is that a behaviour change updates every affected document in
the same change. The check-in's silence is documented in three places as *the designed
hold is already named in the log*, which stops being true once an outlived hold earns a
root line.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract.
- `plugins/workaholic/skills/moderate/SKILL.md` — the tick's voice and its gates.
- `CLAUDE.md` — the `/moderate` row and the check-in paragraph.
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — its own header,
  which carries the retired reasoning verbatim.


## Implementation Steps

1. State the boundary once, where the tick's voice is defined: an `all_held` tick whose
   arrears outlived the designed hold supplies an event; one inside the window does not.
2. Correct the step header's own reasoning in place rather than appending to it — it
   currently says every case but `cap_spent`/`cap_unbounded` supplies no event, and names
   the designed hold as the reason.
3. Say what did **not** move: the keys, the caps, the holds, `ask-question.sh`, the diff
   rule, and which questions are asked.
4. Name the refused alternative (an escalation after N ticks) with its reason, so the
   fork is not re-litigated.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each of the four documents states the new behaviour and none still asserts that every
  non-cap case supplies no event.
- The refused alternative and its reason are recorded once, not four times.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `outputs/` regenerated in the same change; no document left asserting the retired
  reasoning.


## Considerations

- The step header is long and argues its own history; the correction belongs in place,
  because a header that argues for the behaviour it no longer has is worse than none.

