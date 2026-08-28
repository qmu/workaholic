---
created_at: 2026-08-28T21:20:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Name the standing rulings in one place

## Overview

PROPOSED. The loop already reads both standing rulings — `unattributed-work.sh` names
four active missions and one loose ticket no direction claims, and
`audit-identity-coverage.sh` names the addresses no mapping entry covers — but they are
two readings in two vocabularies, each surfacing as its own hourly question. Compose them
into one set so a later ticket can draft the whole set as one diff.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/list-standing-rulings.sh` — new; the one
  reader, composing the two below and owning only the assembly
- `plugins/workaholic/skills/strategy/scripts/unattributed-work.sh` — composed; names the
  active missions and queued tickets no direction claims
- `plugins/workaholic/skills/workaholify/scripts/audit-identity-coverage.sh` — composed;
  emits `uncovered[]` with the exact `<login>=<address>` line that would cover each
- `plugins/workaholic/skills/strategy/scripts/closing-residue.sh` — the assembly shape to
  copy: per-block `readable`/reason, null counts on a degraded block, `exhaustive: false`
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for the reader

## Implementation Steps

1. Write `list-standing-rulings.sh [--root <.workaholic>]` as a **pure read**: it writes
   nothing, creates nothing, exits 0 always.
2. Compose the two existing readers and **walk nothing itself** — no second walker, no
   relation of its own, no field on any artifact. `closing-residue.sh`'s header states the
   rule this must hold to.
3. Emit one entry per candidate ruling, each carrying: `kind`
   (`attribution` | `identity_mapping`), `subject` (the mission slug, or the address), the
   **evidence already on the composed reading** (for an attribution, the mission's path and
   its queued-ticket count; for an address, the artifact count), and the **exact one-line
   repair** (the `carry-attribution.sh <strategy> <mission>` pair, or the proposed
   `<login>=<address>` line).
4. Give each **source** its own `readable` and `reason`; a degraded source reports **null**
   counts, never zeroed ones, and the top-level `readable` names which source failed
   (`unattributed_unreadable:<reason>` / `identity_unreadable:<reason>`).
5. Set `exhaustive: false` unconditionally — both composed readers are lossy and say so, so
   this one inherits it rather than implying an answer it cannot give.
6. Add hermetic coverage: an honest read, a degraded read per source, and an empty read
   that reports honest zeros rather than a degradation.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `list-standing-rulings.sh` emits both kinds of candidate with evidence and repair on each.
- It writes nothing anywhere and exits 0 on every path, including both degraded reads.
- A degraded source reports `readable: false`, its own reason, and **null** counts.
- `exhaustive` is `false` on every output.
- No new walk of `missions/`, `tickets/` or the `feedback:` relation exists in the script.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A read over a fixture with each source removed in turn, asserting null counts and the
  named reason.

**Gate** — what must pass before approval:

- The script's own text reaches `unattributed-work.sh` and `audit-identity-coverage.sh` and
  no other reader of those two facts.

## Considerations

- The temptation is a third reading that "improves" the attribution guess. Refused: this
  assembles what the two readers already say and adds no judgement of its own — the
  judgement is the next ticket's, and it is the run's, never a script's.
