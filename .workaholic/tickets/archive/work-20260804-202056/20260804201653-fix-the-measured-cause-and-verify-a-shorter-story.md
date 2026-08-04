---
created_at: 2026-08-04T20:16:53+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash:
category: Changed
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

## Final Report

Development completed as planned.

### The cause this change is bound to

From the measurement ticket: holding the workload constant at one ticket per story,
stories grew 101.0 → 126.7 body lines (+25%). The predecessor's four *existence* edits
each delivered (−23.8 lines together) and were swamped by +49.8 lines of prose in the
sections that always exist. The named cause is that **the template bounded which sections
exist and never how long one may be** — "1-3 sentences", "one paragraph each", "brief"
carry no number and cannot be checked, and the one section with a real number (Journey,
"50-100 words") was the one that did not grow.

### The change: a line budget per section

`plugins/workaholic/skills/report/SKILL.md` gains *Every section has a line budget* beside
*Omit, never pad*, and `skills/review-sections/SKILL.md` carries the same numbers on the
three sections it writes. **The budgets are not invented** — each is the measured
2026-08-01 per-section mean, the length these sections had before the growth: Overview 12,
Motivation 9 (+3 with a past-context paragraph), the journey diagram 16, each `### 3-N.`
ticket block 9, Outcome 5, each Concerns block 7, Patterns 6, Notes 4.

Two rules ride with them. **A section over budget is cut, not justified** — the budget is a
writing instruction, not a validator, so the failure mode to avoid is appending a sentence
explaining why this branch needed more. And **`## Handoff` and `## Deployment Evidence` are
exempt**: both are evidence rather than prose, and shortening evidence deletes a record.
Concerns are budgeted *per block* for the same reason — the number of concerns is never
trimmed to hit a number, only the words spent on each.

No structural edit rides this ticket: no section was added, removed, folded, or renumbered,
and `filter-low-concerns.sh` / `extract-deferred-concerns.sh` are untouched.

### Verification: the same branch, regenerated

`work-20260804-112404` (one archived ticket, shipped at 142 raw lines) regenerated under
the budgets from the same commit, ticket and evidence — same facts, both concerns kept,
both severities kept, both **How to Fix** lines kept, Deployment Evidence byte-identical.
Measured with the same instrument that found the growth:

| Section | Shipped | Regenerated | Δ | Budget |
| ------- | ------: | ----------: | -: | -----: |
| Changes | 39 | 30 | −9 | 16 diagram + 9 per block |
| Concerns (2 blocks) | 24 | 16 | −8 | 7 per block |
| Motivation | 20 | 9 | −11 | 9 |
| Overview | 19 | 12 | −7 | 12 |
| Successful Development Patterns | 15 | 6 | −9 | 6 |
| Outcome | 9 | 5 | −4 | 5 |
| Deployment Evidence | 8 | 8 | 0 | exempt |
| **TOTAL body** | **135** | **87** | **−48 (−36%)** | |

Raw file lines 142 → 94. Every budgeted section lands exactly on or under its budget, and
the reduction is carried entirely by the sections the measurement named — the exempt
evidence section is unchanged. An omitted section costs **zero** lines, not one: Release
Preparation and Notes are simply absent, with no "None" anywhere in the file.

`node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs` and
`layout-doctor.sh` are clean; `node scripts/test-workflow-scripts.mjs` reports 2134 passed,
0 failed.

### Discovered Insights

- **Insight**: An "omit when empty" rule saves a bounded amount and then stops, while an
  unbounded section grows without limit — so a template that only governs existence loses
  to prose drift on a long enough horizon.
  **Context**: This is why the fifth structural edit would have failed like the first four.
  Any future length complaint about a `.workaholic/` artifact should ask what bounds the
  parts that always exist, before asking which part to remove.
- **Insight**: A high bar stated as prose does not hold. "Omit unless a pattern was really
  found" was already written, and Patterns appeared in **every** story on both sides of the
  change while doubling in length.
  **Context**: The bar needed a number beside it, and the same is likely true of any other
  "only when it matters" instruction in this repo's skills.
