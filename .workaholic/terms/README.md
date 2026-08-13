---
title: Terms
description: The project's glossary — one file per term family, plus the ledger of known terminology conflicts
category: developer
modified_at: 2026-08-13
---

# Terms

**The project's glossary.** One file per term family; each entry gives a term, what it
means *here*, and what it is not.

## What this area holds

A term earns an entry when this project uses it in a way a competent reader would
otherwise have to guess at — because the word is overloaded (`mission`, `story`,
`concern`), because it is this project's coinage (`publish tree`, `PR-unit`,
`claim`), or because two areas of the system use it differently and the difference
matters. `inconsistencies.md` records exactly that last case: **it is a term entry
like any other and carries no special status** — a ledger of known conflicts, read
the same way, refreshed by the same act.

## What it never holds

- **How-to prose.** A guide belongs in the repository's own `docs/` tree.
- **Current-state documentation** — how a thing works today. Also `docs/`. (The
  `specs/` area that used to hold it was retired on 2026-08-13 for the reason this
  README exists to prevent.)
- **A term used in its ordinary sense.** A glossary that defines every word defines
  none of them.

## Who writes it, and when

**A human**, when a term is coined or re-defined. No command, hook, or routine writes
here — the loop uses the vocabulary, it does not get to decide it.

## How staleness becomes visible

This area survived the 2026-08-13 layout reshape (issue #436) on one condition: that
"kept updated" stop being aspirational. `plugins/workaholic/skills/report/scripts/area-freshness.sh`
reports, for every record here and in `deployments/`, how many days since its last
commit and whether it still names something this repository has retired — a de-listed
`.workaholic/` area, or a retired plugin namespace. `/report` reads it beside
`doc-drift.sh`.

It **reports; it never writes.** A glossary a machine maintained would define the words
the machine already uses, which is the opposite of what a glossary is for.

**Current state, stated plainly**: five of the six records here are flagged. They date
from 2026-03-10 and still define `drivin`, `trippin`, `scanner`, `guides` and
`policies` — names retired since. Conforming their frontmatter (this change) is not the
same as re-reading their prose; that content audit is its own work and its own ticket.

- [core-concepts.md](core-concepts.md) — the vocabulary of the system itself
- [artifacts.md](artifacts.md) — what each `.workaholic/` artifact is called and means
- [workflow-terms.md](workflow-terms.md) — the verbs: drive, archive, report, ship
- [file-conventions.md](file-conventions.md) — naming patterns and directory structures
- [inconsistencies.md](inconsistencies.md) — known terminology conflicts
