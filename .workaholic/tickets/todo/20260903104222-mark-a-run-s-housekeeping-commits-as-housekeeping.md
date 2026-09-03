---
created_at: 2026-09-03T10:42:22+09:00
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
