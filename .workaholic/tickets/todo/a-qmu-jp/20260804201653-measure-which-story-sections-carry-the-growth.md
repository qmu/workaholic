---
created_at: 2026-08-04T20:16:53+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-the-branch-story-measurably-shorter
merge_policy:
---

# Measure which story sections carry the growth

## Overview

The predecessor mission made four structural template edits and stories got
**longer**: mean 127 lines (2026-08-01, eight stories) → 164 (2026-08-03〜04,
ten stories), +29%. The mission's stated first act is to measure which sections
actually carry the added lines before touching the template a fifth time. This
ticket produces that measurement, per section, over the same before/after story
sets, and names the cause.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:planning` / measurement policies — name the cause from data before choosing the lever

## Key Files

- `.workaholic/stories/` — the before set (stories dated 2026-08-01, 8 files) and the after set (2026-08-03〜04, 10 files)
- `plugins/workaholic/skills/report/` + `skills/review-sections/SKILL.md` — the generator whose behavior the numbers will indict
- `plugins/workaholic/skills/gather/scripts/` — a natural home if the section-measure becomes a reusable script

## Implementation Steps

1. Split each story in both sets by its `##`/`###` headings and count lines per
   section; produce a per-section table: mean before, mean after, delta, share
   of the total +37-line growth.
2. Check the confounder the mission suspects: are the after-branches simply
   bigger (tickets per branch, diff size)? Normalize per driven ticket where
   possible, so a structural cause is not claimed from a workload difference.
3. Name the cause in one paragraph — which sections grew, whether the growth is
   padding (prose where one line would do), a new section's arrival, or
   workload — with the numbers beside it.
4. Record the finding durably: the ticket's Final Report carries the table; if
   the measure is scripted, land it as a small POSIX script under the gather
   skill so the after-fix ticket can rerun it identically.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A per-section before/after table over exactly the two named story sets exists in the Final Report
- The growth is attributed with the workload confounder explicitly addressed
- The measurement is rerunnable (script or documented one-liner) for the after-fix comparison

**Verification method** — the commands/tests/probes that prove them:

- Rerunning the documented measure reproduces the table's totals (127/164 means within rounding)

**Gate** — what must pass before approval:

- Measurement only — no template or generator change rides this ticket

## Considerations

- Keep the analysis inside the repo (story files are the input; no external
  tooling).
- If the growth turns out to be workload after normalization, the mission's
  second ticket pivots to a per-ticket length target rather than a section fix
  — say so in the report rather than forcing a section villain.
