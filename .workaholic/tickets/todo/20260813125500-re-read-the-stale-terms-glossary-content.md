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
