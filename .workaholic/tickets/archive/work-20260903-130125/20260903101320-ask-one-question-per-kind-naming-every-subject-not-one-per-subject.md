---
created_at: 2026-09-03T10:13:20+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Ask one question per kind naming every subject, not one per subject

## Overview

One morning sent five `🙋` questions in twenty-four seconds, three of them the same sentence
with a direction slug swapped. `lib/question-id.sh` derives a question id per **subject**, so a
step with N candidates asks N questions, and the per-tick cap only spaces them out. Make a step
able to ask **one** question of a kind that names every subject it holds, so three arrived
directions cost one reply.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here

## Final Report

**Outcome**: implemented.

`step-direction-health.sh` now hands back **`groups`** beside `directions`: one entry per reading,
carrying the union of the assignees and every subject it holds. `commands/moderate.md` — the surface
where the agent composes the post — states that a step handing back `groups` asks **one question per
group**, so three arrived directions cost one reply.

**The key carries the sorted subject set, not the kind alone, and the cost is stated.** A bare
`direction-arrived` key would be asked once **ever**, so a direction arriving next week would never
be asked about at all — the asked-once gate turned into a silence, which is a worse defect than the
one being fixed. Keying on `direction-<reading>:<slug1>+<slug2>+…` keeps the gate honest; the cost is
that a fourth direction joining an already-asked group re-asks that whole group once. One extra
question, against the measured five in twenty-four seconds.

**`lib/question-id.sh` is untouched.** It already truncates to 24 characters and appends a digest of
the **whole** key, so a long group key stays injective — the property that file exists for.
`directions` is untouched beside `groups`, because the composer still needs each subject's own
`heading` and `body`; removing it would trade one defect for a worse one. **A group of one renders
exactly as it did before.**

**No addressee, cap, gate or precedence moved.**

**Ticket shape, noted rather than passed over**: this ticket carried an `## Overview` and
`## Policies` and nothing else — no `## Key Files`, no `## Implementation Steps`, no
`## Quality Gate`, which `validate-ticket.sh` requires of a queued ticket. All five in this mission
are the same. The Overview was specific enough to drive from; the gap is reported in the branch
story rather than silently absorbed.

**Verified**: `node scripts/test-workflow-scripts.mjs`, plus a live run of the step against this
repository, which returns one group per reading with its subject count.
