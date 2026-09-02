---
created_at: 2026-09-02T06:28:57+00:00
status: done
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

## Final Report

Development completed as planned.

### Step 1 — reproduced and localized before writing anything

Nothing in the claim chain reads a mission at all. Each reader, and the one reading it makes:

| Script | Keyed on | What it reads |
| ------ | -------- | ------------- |
| `list-claims.sh` / `lib/claims.sh` | a branch | the `Claim <unit>` commit subject, the branch tip's age, the unit's **tickets** on the base, and the branch's diff against the base |
| `list-retirable-claims.sh` | a unit | the claim rows above, plus `branch-pull-request-state.sh` |
| `branch-pull-request-state.sh` | a branch | the newest pull request for that head — `merged` / `closed_unmerged` / `open` / `none` |

`claims_tickets_for_mission` reaches a mission's **tickets** by their `mission:` relation and
never opens the mission file; no script in `drive/scripts/` reads a mission's area or `status:`.
What the closed pull request already answers is *what became of this branch's diff*, which is a
fact about the branch; whether the **work** is still wanted is a fact about the mission, and it
is the one nothing answered.

### Discovered Insights

- **Insight**: `mission/scripts/summary.sh` — the composition point the ticket named — could not
  be the one: it reports only the **active** missions that are the caller's business, so an
  archived mission is invisible to it by construction and an ownership gate would decide a
  question that has nothing to do with ownership. `list.sh` was the second choice and was
  **withdrawn while driving the next ticket**: it enumerates every mission and computes each
  one's progress, and `list-retirable-claims.sh` calls this reader once per unit, so composing
  it made the candidate scan O(units × missions) in a path that runs every tick. The composition
  is `mission/scripts/lib/resolve.sh` — the one resolver every mission script already uses,
  which searches `active/` then `archive/`, so the **area** falls out of the path it returns.
  **Context**: Three candidate compositions, and what ruled each out was different: an ownership
  gate, a cost, and finally none. The area — this reader's whole answer — needs no frontmatter
  at all, and only the ride-along `status:` does.
- **Insight**: `active` and `not_active` are **not** the same class of reading, and the table
  says so. `not_active` cannot become false by looking again — `close.sh` is the only writer of
  an end state and re-opening is offered nowhere — which is exactly the `pull_request_closed_unmerged`
  argument. `active` is designed to become false the moment somebody closes the mission, which
  is the one property a proof must not have.
  **Context**: Classifying both alike would have handed a later consumer an act-licence on the
  reading that changes, which is how a live branch gets deleted.
- **Insight**: A `batch-<ts>` unit had to be a **third answer** rather than either verdict. It
  names no mission, so `not_active` would retire every batch claim in a repository by
  construction and `ok: false` would call a correct reading a degradation.
  **Context**: The same three-way shape `branch-pull-request-state.sh` uses for `none` — a
  successful lookup that found nothing is a fact, not a failure.
