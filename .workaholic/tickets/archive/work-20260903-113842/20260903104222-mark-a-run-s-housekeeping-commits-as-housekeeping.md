---
created_at: 2026-09-03T10:42:22+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# Mark a run's housekeeping commits as housekeeping

## Overview

The ask asks that a run's housekeeping commits be named as such, so whatever composes the squash
body can exclude them by rule rather than by pattern-matching a title. Titles are the wrong key:
`Refresh heartbeat` is one wording of one writer, and the next housekeeping commit will carry
another. A trailer is machine-readable, invisible to a reader's eye, and the shape `claim.sh`
already uses for its `Unit:` line.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `plugins/workaholic/skills/commit/scripts/commit.sh` — the one writer of the trailer block;
  the marker is emitted here and nowhere else.
- `plugins/workaholic/skills/commit/SKILL.md` — *The trailer block*, which enumerates the trailers
  and must name the new one.
- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — writes `Refresh heartbeat`.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — writes the claim stamp with its `Unit:`
  trailer.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` and the archive/hours seams — the other
  commits a run makes for its own bookkeeping.


## Implementation Steps

1. Add a `--housekeeping <kind>` option to `commit.sh` that emits one `Workaholic-Housekeeping:
   <kind>` trailer. Callers stay trailer-agnostic, as they already are for `Category:`.
2. Enumerate the kinds as a closed set (`heartbeat`, `claim`, `index`, `hours`) and refuse an
   unlisted one with `bad_housekeeping_kind`, writing nothing.
3. Pass the flag at each housekeeping writer: `heartbeat.sh`, `claim.sh`, and each index/hours
   seam. A commit that carries a unit's actual work never takes it.
4. State the marker in `skills/commit/SKILL.md` beside the existing trailers, and in `CLAUDE.md`'s
   commit-trailers bullet.
5. Add a hermetic row asserting the trailer is present on a housekeeping commit and absent on an
   ordinary one.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A heartbeat, a claim stamp and an index refresh each carry a `Workaholic-Housekeeping:` trailer.
- An ordinary work commit carries none.
- An unlisted kind is refused by name with nothing committed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `git log --format='%s%n%b'` over a driven unit's branch, confirming which commits carry it.

**Gate** — what must pass before approval:

- The kind set is closed and the refusal is tested.
- `commit.sh` stays the only writer of the trailer.


## Considerations

- Commits already on the trunk carry no marker and are not rewritten — the ask says so explicitly.
  The composer must therefore treat an unmarked commit as ordinary work, which is the safe
  direction: it over-includes on history and under-includes on nothing.
- The subject-line gate is untouched; a trailer is not a subject.

## Final Report

**Outcome**: implemented.

`commit.sh` gained `--housekeeping <kind>`, emitting one `Workaholic-Housekeeping: <kind>` trailer.
The kind set is closed — `heartbeat | claim | index | hours` — and an unlisted one is refused
`bad_housekeeping_kind` **before the staging section**, so nothing is committed and the working tree
is untouched. `commit.sh` stays the trailer's only writer; callers remain trailer-agnostic, exactly as
they are for `--category`.

**Passed at two writers, not four, and the difference is the ticket's own rule.** `heartbeat.sh` takes
`--housekeeping heartbeat`; `claim.sh` takes `--housekeeping claim` at both its stamps (the fresh claim
and the resume takeover). The **index and hours seams take none** — and that is conformance rather than
an omission: neither commits through `commit.sh` on its own. `refresh-index.sh` runs *inside*
`archive.sh` so the refreshed index rides the archive commit, and that commit moves the ticket, which
is a unit's actual work. The ticket says in its own step 3 that *a commit that carries a unit's actual
work never takes it*, so marking it would be wrong. Stated here rather than left as a silent
four-minus-two.

**Verified**: `node scripts/test-workflow-scripts.mjs`, including the row that commits two commits with
the identical subject `Refresh heartbeat` — one marked, one not — and asserts the marked one is dropped
from the composed body while the unmarked one survives. That is the assertion a title-keyed filter
cannot pass, and it is also the guarantee that history already on the trunk is treated as ordinary work.
