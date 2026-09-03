---
created_at: 2026-09-03T10:13:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Stop promising an act no step is obliged to keep

## Overview

The tick said, twice in one morning, that "the next `[Implement]` tick will try to resolve each
conflict itself" — across many ticks while nothing tried, because those units were excluded from
claiming. A recurring promise no step is obliged to keep is worse than silence. Say what will
happen only when the tick can derive it, and otherwise say what is true.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here

## Final Report

**Outcome**: implemented.

**Localized first**: the promise was in five places, not one — `step-stuck-prs.sh`,
`step-stranded-publications.sh` (three of them: a summary and two events), `step-undelivered-units.sh`
and `step-merge-conflicts.sh`. Every one said some form of *the next `[Implement]` tick attempts
each*, and a grep now returns none.

**Why the tick could not have known it was true**, which is the part worth recording: whether a unit
is offered at all is `plan-units.sh`'s answer, and **no `/moderate` step may reach it** — the survey
runs the living migrations and *stages* what they converge, which is why that composition has been
refused here before. So the promise was not merely optimistic; it was underivable at the surface that
made it.

**What replaced it is what is true**: *resolving this belongs to an `[Implement]` run rather than to
this tick, which reads and does not merge.* It names **whose act it is** and says nothing about
**when** — the distinction the ticket asked for. The two `event` strings lost the clause entirely and
now name the repository fact alone (`a published artifact collides with the base`), which is what a
root line is for.

**And the rule is stated where posts are composed**, in `commands/moderate.md`'s closed list of what a
rendered post never carries, with the measurement and the *say what will happen only when the tick can
derive it* test written beside it — so the next contributor meets the rule rather than the symptom.

**Verified**: `node scripts/test-workflow-scripts.mjs`; `sh -n` on all four changed scripts.
