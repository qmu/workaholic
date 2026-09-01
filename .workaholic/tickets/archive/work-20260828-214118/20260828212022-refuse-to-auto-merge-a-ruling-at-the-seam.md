---
created_at: 2026-08-28T21:20:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Refuse to auto-merge a ruling at the seam

## Overview

PROPOSED. A ruling merged by a machine is not a ruling. `publish-tree-pr.sh` already
derives `strategy_touching` from the tree it is publishing and leaves that pull request
open whatever the caller asked for; carry the same exemption to a ruling, in the seam
rather than in the caller, so no future caller can merge one by forgetting.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — derives
  `merge_reason: strategy_touching` from the published tree today; gains `ruling_touching`
  in exactly that shape
- `plugins/workaholic/skills/specificate/SKILL.md` — records the exemption's premise the
  new reason extends
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md` — the behaviour statement moves in
  the same commit
- `scripts/test-workflow-scripts.mjs` — pins that a ruling never merges

## Implementation Steps

1. In `publish-tree-pr.sh`, derive **`ruling_touching`** from the tree being published — a
   path under `.workaholic/missions/` carrying a carried-attribution change, or
   `.claude/git-identities` — beside the existing `strategy_touching` derivation, and leave
   the pull request open whatever `WORKAHOLIC_AUTO_MERGE` says.
2. **The seam's rule, never the caller's.** The reason `strategy_touching` moved into the
   seam on 2026-08-27 applies here with the same force: a caller leaving a variable unset
   is a judgement a future caller can forget, and forgetting merges an operator's ruling
   with nobody having ruled.
3. Report `merged: false`, `merge_reason: ruling_touching` — the exemption **working**, and
   never rendered as a merge failure by any consumer.
4. Keep every other path byte-identical: a publication touching no ruling still merges
   under `WORKAHOLIC_AUTO_MERGE=1`, and a scan finding still holds a pull request open
   under its own reason.
5. Distinguish it from `strategy_touching` rather than widening that word — the two name
   different trees and different operator acts, and one word answering two questions is how
   the two drift.
6. Update `CLAUDE.md` and `rules/workaholic.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tree carrying a drafted ruling reports `merged: false`,
  `merge_reason: ruling_touching`, whatever `WORKAHOLIC_AUTO_MERGE` says.
- A tree touching no ruling merges exactly as it does today.
- `strategy_touching`'s derivation and wording are unchanged.
- The documentation states the new reason in the same commit.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A publish over a ruling fixture with `WORKAHOLIC_AUTO_MERGE=1`, asserting the open pull
  request and the reason.

**Gate** — what must pass before approval:

- A breaker: making the refusal caller-supplied rather than seam-derived must fail.

## Considerations

- The derivation must not catch an ordinary mission write. A carried-attribution diff and a
  new mission are both under `.workaholic/missions/`, so the test is on the **shape of the
  change** (a `feedback:` line appended to an existing mission) rather than on the
  directory alone — this is the ticket's one real design risk and it is where the drill
  should bite.

## Final Report

Development completed as planned.

`publish-tree-pr.sh` derives `ruling_touching` from the tree being published, beside the
existing `strategy_touching` derivation, and leaves the pull request open whatever
`WORKAHOLIC_AUTO_MERGE` says. The test is on the **shape of the change**: a mission that
already existed on the base (`M`) whose diff moves its `feedback:` line — exactly and only
what `carry-attribution.sh` writes — or any touch of `.claude/git-identities`.
`strategy_touching`'s derivation and wording are untouched; a new mission, an ordinary
mission edit and a publication touching neither all merge exactly as before.
`CLAUDE.md`, `rules/workaholic.md` and `specificate/SKILL.md` moved in the same commit.

### Discovered Insights

- **Insight**: `specificate/SKILL.md` asserted that "an attribution carry is
  byte-indistinguishable from any other mission write, so the seam **cannot** see it" —
  which is false, and was the whole reason step 9e's guarantee was recorded as weaker than
  the strategy exemption's. An ordinary proposal **adds** a mission; a carry **modifies**
  one that is already on the base. That single bit is what makes the seam-level refusal
  possible at all, and the paragraph is superseded in place rather than left standing.
  **Context**: the ticket's stated design risk and its resolution are the same fact.
- **Insight**: `jq`-free shell needs care here — a `while read` loop that `break`s inside a
  pipeline runs in a subshell, so the hit is emitted on stdout and captured by the
  enclosing command substitution rather than assigned to a variable.
  **Context**: the same shape appears in every per-path scan in this script.
