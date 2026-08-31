---
created_at: 2026-08-31T11:31:18+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notice-a-periodic-artifact-that-stopped-being-produced
merge_policy:
verification_handoff: 
---

# State where a cadence is declared and what it says

## Overview

Nothing in this repository declares *what should keep being produced, and how often*, so
the reading the rest of this mission needs has no input. **Decide the home and the shape
and state it**, following `log_locator:`'s discipline exactly: optional, non-secret,
absent means nothing is declared, one reader, and a repository that declares nothing
behaves as it does today. This ticket owns the decision, with its reasoning, so the
reader and the step that follow have one settled answer to read.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/workaholic.md` — the `.workaholic/` conventions table, and
  where a new declared field is stated.
- `plugins/workaholic/skills/moderate/scripts/step-workload-logs.sh` — the declaration
  discipline the ask names: a non-secret locator, a named credential *variable*, a
  checked absence rather than a forecast.
- `plugins/workaholic/skills/story/scripts/area-freshness.sh` — the precedent that
  already reports `stale_days` and says the right interval differs per project, which is
  precisely the number this declaration supplies.
- `.claude/settings.json` — one of the three candidate homes (see Considerations).


## Implementation Steps

1. Choose the home among the three candidates in Considerations, and **write the reason
   down** — which one, and why the other two lose. Do not add a `.workaholic/` top-level
   area without registering it in **both** lockstep sources in the same commit
   (`hooks/workaholic-layout-allowlist.txt` and the `rules/workaholic.md` table).
2. Fix the shape: a **name**, a **path pattern** the cadence's artifacts match, and a
   **period**. Nothing else — no credential, no command, no schedule expression that
   would duplicate a routine's `cron_expression`.
3. State the absent case explicitly: no declaration is a healthy silence, never a finding
   and never a degradation.
4. State it once, where the convention lives, and reference it from the reader rather
   than restating it there.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The home, the shape and the absent-means-nothing rule are each stated once, in one
  place, with the losing candidates named and their costs recorded.
- Any new `.workaholic/` top-level directory is registered in both lockstep sources in
  the same commit, and `layout-doctor.sh` reports `conforming: true`.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No credential and no command enters the declaration; the field names a pattern and a
  period and nothing else.


## Considerations

The three candidate homes, with what each costs:

- **The area's own `README.md` frontmatter.** Every `.workaholic/` area has one, it is
  hand-maintained by the person who knows the cadence, and `area-freshness.sh` already
  reads such frontmatter. Cost: it can only ever declare a cadence for a `.workaholic/`
  area, and the measured artifact may live outside the tree entirely.
- **The repository's own configuration** (`.claude/settings.json`'s `env` block). The
  2026-08-29 precedent for a per-repository value with no artifact and no migration.
  Cost: a list of (pattern, period) pairs inside one environment variable is awkward to
  read and easy to mistype, with no validator.
- **A new `.workaholic/` top-level area.** Cleanest to read and validate. Cost: an area
  amendment in two lockstep sources, and an area whose only writer is a human is exactly
  the shape that went stale and was retired in 2026-08-13.

This is a decision the driving session makes and records — deliberately **not** an
`## Open Decisions` item, because nothing unattended can clear one of those and the
choice here is a design judgement rather than a ruling only the operator can give.

