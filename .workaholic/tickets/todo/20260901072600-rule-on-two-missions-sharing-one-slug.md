---
created_at: 2026-09-01T07:26:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: 20260826071745-say-when-the-loop-has-run-out-of-direction.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
---

# Rule on two missions sharing one slug

## Overview

`main` carries **two** tracked `mission.md` files whose `slug:` is
`say-when-the-loop-has-run-out-of-direction` — one under `missions/active/`
(`created_at: 2026-08-26T07:19:28`, `feedback: [20260826071745-…]`) and one under
`missions/archive/` (`created_at: 2026-08-26T08:19:15`, `status: achieved`,
`actual_hours: 1.1`, `feedback: [20260826081729-…]`, `claim: work-20260826-084111`).
Different records, different asks, one slug.

Measured on 2026-09-01 while driving the active one: its eight tickets were archived,
`progress.sh` read `{checked: 3, total: 3, unlinked: 0}` and `queue-size.sh` read `todo: 0`,
so the archive gate proved it `achieved` and stamped the field — and the record stayed in
`missions/active/`, because the destination path under `missions/archive/` is already
occupied by the other mission.

The slug is the key every reader uses. `mission/scripts/read-relation.sh`,
`mission-strategy.sh`, `close.sh`, `progress.sh`, `queue-size.sh` and `plan-units.sh` all
resolve a mission by slug, searching `active/` then `archive/` — so with two records the
answer depends on which area is searched first, and the loser is unreachable by name.

**This ticket does not pick a repair.** Two records that were both real work cannot be
merged by a script without losing one of them, and deleting either destroys a driven
mission's history. What is needed first is a ruling on which record is authoritative and
what happens to the other.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a reading that could not be made is named

## Key Files

- `.workaholic/missions/active/say-when-the-loop-has-run-out-of-direction/mission.md` — the
  record this run drove and closed; still in `active/` with `status: achieved`.
- `.workaholic/missions/archive/say-when-the-loop-has-run-out-of-direction/mission.md` — the
  earlier-closed record occupying the destination.
- `plugins/workaholic/skills/mission/scripts/close.sh` — the one writer of an end state; it
  stamped the field and could not complete the move.
- `plugins/workaholic/skills/mission/scripts/summary.sh`, `read-relation.sh`,
  `mission-strategy.sh` — the slug-keyed readers whose answer is now area-order dependent.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — surveys `active/`, so an
  `achieved` record left there is a survey input.

## Implementation Steps

1. Establish the facts before proposing anything: read both records in full and both
   feedback refs they cite, and state what each mission actually asked for. They are
   different asks that were given the same slug, not one record duplicated.
2. Determine how the collision was created — whether `/specificate` or `/mission` can mint a
   slug that already exists in either area, and whether any writer checks both areas before
   choosing one. That answer decides whether this is a one-off to clean up or a seam to close.
3. If a writer can mint a colliding slug, close that seam: refuse the collision by name at
   creation, checking **both** areas, with nothing written on the refusal.
4. Give `close.sh` an honest answer for an occupied destination. It currently stamps the end
   state and leaves the record in `active/` with no word to the caller — an `achieved`
   mission sitting in the surveyed area. It must either complete the move or refuse by name
   with the field unstamped; a half-applied close is the state this ticket is about.
5. Decide what a slug-keyed reader owes a caller when two records match. Reporting the
   ambiguity by name is the shape this repository uses everywhere else (`ambiguous_claim`);
   silently taking the first area searched is what it does today.
6. The disposition of the two existing records is a **ruling, not a step** — see Open
   Decisions. Do not delete, merge, rename or re-slug either record without it.

## Open Decisions

- **Which of the two records is authoritative, and what becomes of the other?**

  **Sources consulted.** `CLAUDE.md`'s *Mission lifecycle* paragraph in full: it states
  `status: active | achieved | abandoned | carried`, that `close.sh` is the **only** writer
  of an end state, that `archive.sh` closes "the one outcome that is arithmetic" and
  **never** `abandoned` or `carried`, "which assert intent". It says nothing about two
  records sharing a slug. `skills/mission/SKILL.md` was read for a uniqueness rule and
  states none — the slug is treated throughout as though it were unique without anything
  establishing that it is. `close.sh`'s own header was read: it writes an end state and does
  not contemplate an occupied destination. Both mission records were read in full, and they
  cite different feedback refs, so neither is a copy of the other.

  **The fork.** Either the archived record stays authoritative and the active one is
  re-slugged to a distinct name before being archived under it — which preserves both
  histories and costs every existing `mission:` relation pointing at the old slug a
  migration — or the two are recognised as one line of work and consolidated into a single
  record, which loses one record's changelog, acceptance and `actual_hours`.

  Nothing in the repository settles which. The records were authored by `a@qmu.jp` and the
  question is whose work each was and whether they were meant to be one mission; that is the
  operator's ruling, and it is available to be made rather than unanswerable.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No slug resolves to two `mission.md` files across `active/` and `archive/`
- A writer asked to mint a slug that already exists in **either** area refuses by name, with
  nothing written
- `close.sh` on an occupied destination either completes the move or refuses by name with
  the end state unstamped — never stamps and leaves the record in `active/`
- No `achieved` mission remains under `missions/active/`
- The disposition of the two existing records follows the Open Decision's ruling; neither is
  deleted, merged or re-slugged before it

**Verification method** — the commands/tests/probes that prove them:

- `git ls-tree -r --name-only origin/main -- .workaholic/missions/` piped through a duplicate
  check on the slug, asserting no slug appears twice
- `node scripts/test-workflow-scripts.mjs` — a case seeding a slug present in `archive/` and
  asserting the creating writer refuses it by name with the tree byte-identical
- A case seeding an occupied destination and asserting `close.sh`'s named refusal, with
  `status:` unchanged in the source record
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The suite passes; the duplicate check is clean; the Open Decision carries a recorded ruling
