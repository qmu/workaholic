---
created_at: 2026-08-13T12:55:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: revive-strategy-and-reshape-the-workaholic-artifact-set
merge_policy:
---

# Re-read the stale terms glossary content

## Overview

Minted mid-run while driving `20260813112618-redefine-the-deployments-and-terms-areas.md`, which gave `terms/` a definition and an upkeep seam but deliberately did **not** re-read its prose — that is a content audit, and the ticket's own Open Decision resolved that conforming frontmatter is not the same as re-reading records nobody has looked at.

The seam it added (`report/scripts/area-freshness.sh`) now measures the problem instead of asserting it. Run against this repository it flags **5 of 6 records**, every one last committed 2026-03-10 (156 days):

| Record | Retired names it still uses |
| ------ | --------------------------- |
| `terms/artifacts.md` | `guides`, `policies`, `specs` |
| `terms/core-concepts.md` | `policies`, `specs`, `drivin`, `trippin` |
| `terms/file-conventions.md` | `guides`, `policies`, `specs`, `trippin` |
| `terms/inconsistencies.md` | `policies`, `specs`, `drivin`, `trippin` |
| `terms/workflow-terms.md` | `specs`, `trippin` |

`drivin` and `trippin` are plugin namespaces merged into the single `workaholic` plugin; `guides`, `policies` and `specs` are `.workaholic/` areas retired on 2026-08-13. A glossary defining names the project no longer has is not merely old — it teaches a reader vocabulary that will not match anything they find.

## Policies

- `workaholic:planning` / `policies/terminology.md` — the glossary is where terminology is arbitrated; a wrong entry there is worse than no entry
- `workaholic:implementation` / `policies/objective-documentation.md` — a definition that names a thing which does not exist is a defect, not a stylistic issue
- `workaholic:design` / `policies/history-structures.md` — a retired term stays readable as history where it is marked retired; it is not silently deleted from a reader's path

## Key Files

- `.workaholic/terms/core-concepts.md`, `artifacts.md`, `workflow-terms.md`, `file-conventions.md`, `inconsistencies.md` — the five flagged records.
- `.workaholic/terms/README.md` — already carries the definition and states the current flagged count; update the "current state, stated plainly" paragraph when the count changes, or the README becomes the next stale record.
- `plugins/workaholic/skills/report/scripts/area-freshness.sh` — the measurement. Its `RETIRED` list is the vocabulary of "no longer exists here" and grows when something else is retired.

## Implementation Steps

1. Read each flagged record against the current system (`CLAUDE.md`, `plugins/workaholic/rules/workaholic.md`, the shipped skills list) and decide per entry: still true, re-word, mark retired, or drop.
2. A term the project genuinely retired (`drivin`, `trippin`, `scanner`, `driver`) is **marked retired with its date and successor**, not deleted — a reader meeting the word in an old story needs to find out what it was.
3. Re-check `inconsistencies.md` against the same reality: an inconsistency between two names that no longer exist is resolved by history, not by a ledger entry.
4. Re-run `area-freshness.sh` and update the README's stated count.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `bash plugins/workaholic/skills/report/scripts/area-freshness.sh` reports `flagged: 0` for `terms/`, or every remaining flag is a deliberate retired-term entry whose record says so in its own text.
- No `terms/` record defines a plugin namespace or a `.workaholic/` area that the shipped plugin does not have.
- `.workaholic/terms/README.md`'s stated current state matches what the seam reports.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/report/scripts/area-freshness.sh` before and after, both quoted in the Final Report.
- `node scripts/test-workflow-scripts.mjs` green.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming.

**Gate** — what must pass before approval:

- The seam's output quoted before and after, suite and layout-doctor green, and a per-record statement of which of the four dispositions each entry received.

## Considerations

- The temptation is to delete the five records and call the area clean. That empties a glossary the surviving definition says the project keeps — and the area was retained on purpose while `guides`/`policies`/`specs` were not. Re-read, do not evacuate.
- A term marked retired still trips `area-freshness.sh`'s name check, which is correct behaviour and not a bug in the seam: the record's own text is what tells a reader the flag is deliberate. If the noise becomes real, the fix is a marker the script honours, decided then rather than pre-built now.

## Final Report

Development completed as planned, with one structural choice the ticket left open.

All five flagged records were re-read against the shipped system (`CLAUDE.md`,
`plugins/workaholic/rules/workaholic.md`, the skills and hooks actually shipped) and
rewritten rather than patched: the March 2026 content described a two-plugin marketplace,
an agent hierarchy of managers and leads, a scan pipeline and three documentation areas,
none of which the repository has. Per-entry the decision was *re-word* for the terms that
survived with a changed meaning (plugin, skill, worktree, archive, commit), *drop* for
entries that named implementation details of retired components, and *mark retired* for
every name a reader can still meet in old history.

**The retired names were collected into one new record rather than annotated in place.**
The ticket asked for retired terms to be marked with date and successor, and its own
acceptance criterion allowed for the resulting flag. Spreading them across the five
records would have left all five permanently flagged, which is indistinguishable from the
staleness the seam exists to report. `terms/retired-terms.md` holds every retired plugin
namespace, area, agent tier, command and workflow concept in five tables with dates and
successors; its opening paragraph states that it is permanently flagged by design. The
four current-vocabulary records and the conflict ledger now name nothing the repository
does not have, so a flag on any of them is a real defect again.

`inconsistencies.md` was cut from twenty-two entries to seven. Every removed entry
recorded a conflict between two names that are both retired — resolved by history, as the
ticket's step 3 anticipated. The seven that remain are live collisions: "policy" in three
senses, `/report` versus the run report, "scan" now meaning the safety scan only,
subject/source/author on a feedback record, four artifacts sharing "release", the
archive verb/noun, and `/fb` versus the host agent's built-in `/feedback`.

### Verification

Before: `flagged: 5, total: 6` — every terms record except the README named a retired
area or namespace.

After: `flagged: 1, total: 7` — only `retired-terms.md`, whose text says so.

- `bash plugins/workaholic/skills/report/scripts/area-freshness.sh` → `{"flagged": 1,
  "total": 7}`; `retired_terms: []` on artifacts, core-concepts, file-conventions,
  inconsistencies and workflow-terms.
- `node scripts/test-workflow-scripts.mjs` → `2590 passed, 0 failed`.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`, zero findings
  (three pre-existing legacy-trip advisories, non-blocking).
- `bash <src>/skills/okf/scripts/refresh-index.sh` → `{"refreshed": true, "indexes": 7}`;
  the new record is listed in `terms/index.md`.

### Discovered Insights

- **Insight**: A word-bounded name check cannot distinguish "defines a retired thing"
  from "records that a thing was retired", so where the retired names live decides
  whether the seam stays useful. Concentrating them in one record keeps the signal
  binary — one expected flag, and any other flag is real — without adding a marker the
  script has to honour.
  **Context**: The ticket's Considerations offered a marker as the fix "if the noise
  becomes real". It did not become real, because the noise turned out to be a placement
  problem rather than a tooling gap. The same shape applies to any future
  reports-never-writes seam: prefer arranging the data so the blunt check is right.

- **Insight**: The glossary had drifted in exactly the way the retired documentation
  areas had, and for the same reason — five months of no reader. It survived the reshape
  on the condition that staleness become visible, and the first run of that seam found
  five of six records wrong. The check paid for itself before the content audit it
  triggered was even written.
  **Context**: `terms/` and `deployments/` are the only hand-maintained areas left. The
  argument that kept them is that a machine-maintained glossary defines the words the
  machine already uses; the price is a check that must actually be read.
