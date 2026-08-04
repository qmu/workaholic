---
created_at: 2026-08-04T20:16:53+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 1h
commit_hash:
category: Changed
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

## Final Report

Development completed as planned. The measure landed as
`plugins/workaholic/skills/gather/scripts/story-sections.sh` (POSIX `sh`, JSON by
default, `--table` for the rendering below), documented in the gather skill.

### The sets, stated so the table is reproducible

The mission's headline figures (127 → 164 over "eight" and "ten" stories) are **not
reproducible**: the file list behind them was never recorded, and no subset of the
stories on those dates reproduces both means. Two sets are therefore defined here
explicitly.

- **Full sets** — every story whose branch is dated 2026-08-01 (n=11) against
  2026-08-03〜04 (n=14). Raw file lines: mean 117.9 → 142.1 (+21%). Same direction and
  close to the same magnitude as the mission's claim.
- **Single-ticket sets** — the same stories restricted to branches that archived
  **exactly one** ticket: n=8 before, n=9 after. This is the like-for-like control and
  every number below comes from it.

### The workload confounder, addressed

The after-branches really are heavier: 1.18 → 1.57 archived tickets per story (+33%).
Two normalizations, and only one of them is valid.

- **Per-ticket division is the wrong control** and inverts the answer: 99.8 → 90.4 lines
  per ticket, i.e. an apparent 9% *improvement*. It is wrong because a story's cost is
  mostly fixed per story (Overview, Motivation, Outcome, the diagram), so a set with more
  multi-ticket stories amortizes that overhead and looks leaner while every individual
  story got longer.
- **Holding the ticket count at one** is the valid control, and the growth survives it
  intact: **101.0 → 126.7 body lines, +25.7 (+25%)**. The growth is structural to the
  writing, not a workload artifact.

### Per-section table (mean body lines per single-ticket story)

| Section | Before (n=8) | After (n=9) | Δ | share of +25.7 |
| ------- | -----------: | ----------: | -: | -------------: |
| Changes | 17.1 | 31.2 | **+14.1** | 55% |
| Concerns | 20.0 | 28.8 | **+8.8** | 34% |
| Deployment Evidence | 2.1 | 9.2 | +7.1 | 28% |
| Successful Development Patterns | 5.9 | 12.8 | +6.9 | 27% |
| Motivation | 8.8 | 15.1 | +6.3 | 25% |
| Outcome | 4.9 | 9.0 | +4.1 | 16% |
| Overview | 12.4 | 14.9 | +2.5 | 10% |
| (title/preamble) | 1.8 | 1.2 | −0.6 | −2% |
| Notes | 3.8 | 1.1 | −2.7 | −11% |
| Historical Analysis | 8.4 | 1.1 | −7.3 | −28% |
| Release Preparation | 16.0 | 2.2 | −13.8 | −54% |
| **TOTAL** | **101.0** | **126.7** | **+25.7** | 100% |

Two sub-measures separate count from verbosity:

- **Concerns held its block count exactly** — 24 `###` concern blocks in both sets — while
  lines per block went **6.7 → 10.8 (+61%)**. Not more concerns; longer ones.
- **Changes carried exactly one ticket block per story in both sets.** Of its +14.1,
  **+6.1 is the mermaid diagram** (8.0 → 14.1 fenced lines per story) and **+8.0 is the
  per-ticket prose**, against a template that asks for "1-3 sentences".

### The cause, named

**The predecessor's four structural edits all worked, and prose growth swamped them.**
Release Preparation −13.8, Historical Analysis folded into Motivation −7.3, Notes −2.7:
−23.8 lines removed, every edit delivering. Against that, the sections that always exist
grew +49.8 with the identical amount of work behind them.

The reason is that **the template governs which sections exist and never how long one may
be**. Every edit the predecessor made was an *existence* edit — omit when empty, fold a
section away, drop `low` concerns from the body — and existence edits have a floor: once a
section is gone it cannot save another line. Length is bounded only by soft phrases that
carry no number and cannot be checked: "1-3 sentences", "one paragraph each", "brief". The
one section with an actual number — Journey, "50-100 words" — is also the one that did not
grow. So a fifth structural edit is the wrong lever, and so is a per-ticket length target
(the per-ticket figure is the misleading normalization above). What is missing is a stated,
checkable **per-section line budget** on the four sections that carry the growth.

Deployment Evidence (+7.1) is deliberately excluded from that: it is a `/ship` record of
what was deployed and confirmed, arriving on 7/9 stories now against 1/8 before, and it is
evidence rather than prose. Shortening it would delete a record, which is the one thing
this mission must not do.

### Discovered Insights

- **Insight**: Dividing a document set's length by its unit-of-work count is the wrong
  control when the document has fixed per-instance overhead — it reported a 9% improvement
  over the same data that a like-for-like comparison showed as a 25% regression.
  **Context**: The story is mostly per-story overhead plus a small per-ticket part, so
  ticket count is a poor denominator. Any future length measurement over `.workaholic/`
  artifacts should hold the work count constant rather than divide by it.
- **Insight**: A measurement whose input set is not recorded alongside it cannot be
  re-run, and its numbers become unfalsifiable claims.
  **Context**: The predecessor's 127/164 could not be reproduced from any subset of the
  stories on those dates, which cost this ticket a reconstruction it should not have
  needed. `story-sections.sh` takes its files as arguments precisely so the set rides in
  the command that produced the table.
