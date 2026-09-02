---
created_at: 2026-09-02T06:28:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: retire-a-claim-whose-work-is-finished-or-abandoned
merge_policy:
verification_handoff: 
---

# Read a claim's mission status from the tree

## Overview

PROPOSED. Retirement is keyed on the branch's own pull request
(`branch-pull-request-state.sh`), so nothing in the protocol can answer *is the work
behind this claim still wanted*. When the operator closes a mission as `abandoned` its
claim branch keeps every reading it had. Supply that missing reading — and only the
reading; the candidate it feeds is the next ticket's.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim-mission-state.sh` — new; the one reader.
- `plugins/workaholic/skills/drive/scripts/branch-pull-request-state.sh` — the shape to
  follow: one subject, one answer, an unreadable read named rather than guessed.
- `plugins/workaholic/skills/mission/scripts/summary.sh` — how a mission's area and
  `status:` are already read; compose it, never a second parser.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the new vocabulary's row
  goes, and where it must be classified proof or judgement.
- `scripts/test-workflow-scripts.mjs` — the suite that fails on an unclassified word.

## Implementation Steps

1. **Reproduce and localize first.** Take a unit id whose mission is in
   `.workaholic/missions/archive/` and show that nothing in `list-claims.sh`,
   `list-retirable-claims.sh` or `branch-pull-request-state.sh` reads the mission at all —
   name the reading each one does make. Record what the closed pull request behind that
   unit already answers, so the new reader is not a second copy of it.
2. Write `claim-mission-state.sh <unit>`: one JSON line, exit 0 always.
   `{"ok": true, "unit", "kind": "mission"|"batch", "state": "active"|"not_active"}` with
   `status` beside `not_active`, and `{"ok": false, "reason": ...}` for a read it could
   not make. A `batch-<ts>` unit has no mission and answers `kind: batch` — a real answer,
   never `not_active`.
3. Compose `mission/scripts/summary.sh` for the area and `status:`; add no second parser
   of mission frontmatter and no field to any artifact. Local tree reads only, no network.
4. An unreadable mission is `ok: false` with its reason, never `not_active` — a wrong
   `not_active` deletes a live branch, which is the asymmetry that decides this.
5. Classify the new words in `drive/reference/claims.md` as a keyed sub-table, naming its
   consumers, and state plainly whether the reading is a proof or a judgement.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose mission is in `missions/active/` answers `active`.
- A unit whose mission is in `missions/archive/` answers `not_active` with its `status`.
- A `batch-<ts>` unit answers `kind: batch` and never `not_active`.
- A mission that cannot be read answers `ok: false` with a named reason.
- The new words are classified in `claims.md` and the suite passes on them.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic case per criterion in `scripts/test-workflow-scripts.mjs`, over throwaway
  repositories, with no network and no `gh`.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- The reader answers *is the work still wanted*, which is a person's decision recorded in
  the tree rather than a proof about content. Whether that makes it strong enough to
  license a delete is the next ticket's question, not this one's.
- `close.sh` is the only writer of a mission's end state, so the reading has exactly one
  source and needs no cursor.
