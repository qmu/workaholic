---
created_at: 2026-08-30T04:28:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# Name each reported claim's mergeability in the report

## Overview

PROPOSED. A claim decaying from `mechanical` to `content` is the moment the loop's
own work becomes a person's, and today it is visible only when the decay has already
happened and a question fires. Naming the class per reported claim in the run report
makes the decay visible **the hour it happens**.

**Evidence, never a verdict.** No gate, sort, claim, route, demotion or token reads
it — the same standing this repository gives `pace`, `overdue`, `expiring`, `arrived`
and the base's own health, each named in a report and read by nothing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §7's run-report contract
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — already renders
  `mergeability` and `mergeability_reason` on every row; nothing new is derived
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — untouched

## Implementation Steps

1. Name each **reported** claim's `mergeability` in the run report, off the row the
   oracle already renders. Derive nothing: a second derivation of one fact is what
   the two candidate sets in this mission's own Goal already cost.
2. Carry `unanswerable` **as unanswerable, by its reason** — never rendered as
   `clean`, which is the reading that would make a decaying claim look healthy.
3. Read it **once per run**, from the scan the run already makes; add no network call
   and no second walk.
4. State in §7 that it moves no token and gates nothing, in the words the other
   evidence-only readings already use.
5. Update `CLAUDE.md`'s `/implement` row in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each reported claim's class is named once per run
- `unanswerable` is named as itself, never as `clean`
- No token moves; no gate, sort, route, claim or survey reads it
- No extra network call and no second scan

**Verification method** — the commands/tests/probes that prove them:

- The drill rows added by this mission's last ticket, asserting the survey and every
  gate byte-identical across a `mechanical` and a `content` claim
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `claim-mergeability.sh` and `list-claims.sh` byte-identical

## Considerations

- Bound it to **reported** claims. Naming the class for every claim on every tick
  turns the report into a claim table, and the fact is only actionable where the unit
  is finished and waiting.
