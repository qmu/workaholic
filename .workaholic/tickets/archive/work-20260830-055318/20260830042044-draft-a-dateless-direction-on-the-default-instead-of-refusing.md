---
created_at: 2026-08-30T04:20:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-a-dateless-direction-with-the-operator-s-one-week-default
merge_policy:
verification_handoff: 
---

# Draft a dateless direction on the default instead of refusing

## Overview

PROPOSED. `/specificate`'s strategy form needs three parts *from the ask itself*:
a date, an owner, an aim with no decomposable plan. An ask carrying two of them is
record-only, `no_target_date` — measured 2026-08-30, three announced directions all
died there and the loop kept planning from the directions that already existed.

The operator has ruled the default. Take it: an ask with an **aim and an owner** but
**no date** drafts the strategy on the one-week default, on the never-auto-merge
path that already exists, where their merge is the authorship and editing the date
before merging is the veto.

`no_target_date` is **narrowed, not deleted**. It still answers the one case a
default must never cover: an ask that *states* a date the run cannot parse. Defaulting
over the operator's own words is the failure this must not introduce while removing
the other one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md` — *The strategy form, and the one
  rule it widens*: the three-part bar and *The owner question the artifact forces*,
  whose last sentence is the rule this ticket moves
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 9b, where the
  date reaches `create.sh`, and step 13's record-only reason list
- `plugins/workaholic/skills/strategy/scripts/default-target-date.sh` — the one
  derivation, from the preceding ticket
- `plugins/workaholic/skills/strategy/scripts/create.sh` — unchanged; it takes a
  `YYYY-MM-DD` and never learns where the date came from

## Implementation Steps

1. Reproduce first: run the strategy form's bar against an ask with an aim and an
   owner and no date, and confirm the outcome is record-only `no_target_date`.
2. In `SKILL.md`, restate the three-part bar: the **date** is taken from the ask when
   it states one, else the one-week default; the **owner** and the **aim** are
   unchanged and neither is ever defaulted. State the operator's ruling and its date
   as the reason, so the default is traceable to a person and not to a preference.
3. Narrow `no_target_date` to *the ask stated a date this run could not resolve to a
   single `YYYY-MM-DD`* and say so where it is named. An ask stating no date at all no
   longer reaches it.
4. In `workflow.md` step 9b, call `default-target-date.sh` with the triggering
   issue's own date when the ask states none, and hand its `target_date` to
   `create.sh`. Every other refusal (`no_assignee`, `assignee_unmapped`,
   `empty_aim`, …) is untouched and still falls back to record-only naming itself.
5. Leave the never-auto-merge rule exactly where it is: the seam derives
   `strategy_touching` from the path, so a defaulted strategy is left open by the
   same mechanism as a stated one. Change nothing about it.
6. Update `CLAUDE.md` and any other affected document in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An ask with an aim and an owner and no date emits a strategy whose `target_date`
  is the default, on a pull request left open
- An ask stating a resolvable date emits that date, byte-identical to today
- An ask stating an unresolvable date is record-only, `no_target_date`
- An ask missing an owner or an aim is record-only under its existing reason

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-specificate`
- `node scripts/test-workflow-scripts.mjs`
- The dateless-ask row added by this mission's last ticket

**Gate** — what must pass before approval:

- No new writer of the strategy artifact; `create.sh` byte-identical
- `publish-tree-pr.sh` byte-identical — the exemption is not re-implemented here

## Considerations

- **The ask offered two endings and this takes one, deliberately.** Its option (1) is
  a directed in-thread question naming the missing part. `/specificate` may not ask at
  any step, so that question would have to be `/moderate`'s — and no step there can
  see a record-only strategy-shaped outcome without a new store or a new field on an
  artifact, which this repository refuses by name elsewhere. The ask's own *done
  means* is satisfied by the default, so the question is not built. If the operator
  wants it as well, it is a separate ask with a separate cost.
- The default lowers the bar on the one artifact that has no floor and no ceiling
  (`SKILL.md`: the three-part bar is the only brake). The owner requirement is what
  still holds it — an unassigned or unmapped issue is record-only exactly as before,
  so a stray ask cannot mint a direction.
