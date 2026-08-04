---
created_at: 2026-08-04T20:16:53+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on: 20260804201653-measure-which-story-sections-carry-the-growth.md
mission: make-the-branch-story-measurably-shorter
merge_policy:
---

# Fix the measured cause and verify a shorter story

## Overview

The second half of the mission: apply the fix the measurement ticket named —
and only that fix — then prove it on the mission's own terms. The predecessor's
lesson is written into the mission Goal: structural template edits made on
assumption produced +29%; this ticket is only allowed to act on the measured
cause, and its verification is a same-branch before/after, not a new-era mean
that a lighter workload could fake.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / UX policies — a story is for its reviewer; length tracks the change's size, not the template's section count

## Key Files

- `plugins/workaholic/skills/report/SKILL.md` + `skills/report/scripts/` — the story generator's guidance
- `plugins/workaholic/skills/review-sections/SKILL.md` — the section content generator (ships cross-agent; rebuild `outputs/` on change)
- The measurement ticket's Final Report — the cause this ticket is bound to

## Implementation Steps

1. Read the measured cause; translate it into the smallest generator/guidance
   change that addresses it (e.g. per-section "stop when said" rules with line
   norms, dropping a padded section, or a per-ticket length budget — whichever
   the numbers named).
2. Apply it to the report/review-sections skills; rebuild `outputs/` if a built
   skill changed.
3. Verify on the mission's criterion: pick a recently reported branch,
   regenerate its story under the new guidance, and compare like-for-like —
   the regenerated story is shorter than the shipped one for the same branch,
   and an empty section renders as one line, not an apology paragraph.
4. Rerun the measurement script over the regenerated story to show the named
   sections shrank — closing the loop with the same instrument that found them.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The change traces line-by-line to the measured cause (no speculative fifth structural edit)
- The same branch's regenerated story is shorter than its shipped story, with the named sections carrying the reduction
- An empty section costs one line

**Verification method** — the commands/tests/probes that prove them:

- The measurement rerun's table, before vs regenerated, in the Final Report
- `node scripts/build-plugins/verify.mjs` clean if `outputs/` was rebuilt

**Gate** — what must pass before approval:

- Both mission acceptance criteria are satisfiable from this branch's evidence

## Considerations

- Do not regress the concern-preservation rule: the story file keeps every
  severity; shortening applies to prose density and the PR-body rendering,
  never to dropping recorded concerns from the file.
- If the measurement pivoted to workload, this ticket implements the per-ticket
  target it proposed instead — the depends_on exists precisely so this ticket's
  scope is decided by evidence, not by this spec.
