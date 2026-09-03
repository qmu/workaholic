---
created_at: 2026-09-03T13:39:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Read a declared probe through one reader

## Overview

One reader answers *what does this unit declare*, so the probe must be read where
`verification_handoff:` already is. This ticket adds the probe to
`verification-handoff.sh`'s output without running it and without changing any verdict — the
route still behaves exactly as it does today.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one reader; `classify` and `consider` carry each member's declaration
- `plugins/workaholic/skills/drive/scripts/declared-handoff-detail.sh` — renders the declaration for `/moderate`'s `handoff-unit` question
- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — reads that detail

## Implementation Steps

1. Read `verification-handoff.sh`'s header in full before touching it: the field's contract, the
   any-member-wins rule, the derived `.claude/` case and the missing-file rule are all stated
   there and none of them may move.
2. Extend `fm_field`'s use in `classify` to read `verification_probe` beside
   `verification_handoff`, and carry it on each `members[]` entry as `verification_probe`.
3. Add `probe` and `probe_member` at the top level, naming the **first declaring member's** probe
   — the same precedence `reason`/`member` already use, so a unit with two probes reports the one
   whose declaration is the reason.
4. A member with a handoff and **no** probe carries `verification_probe: ""`; that empty is what
   the later `unmeasured` reading keys on, so it must be an empty string and never absent.
5. Leave `handoff` itself derived exactly as it is: this ticket runs nothing and decides nothing.
   The derived `.claude/` case carries no probe (nothing can probe a permission prompt) and says
   so with an empty value.
6. Carry the probe through `declared-handoff-detail.sh` so a `/moderate` `handoff-unit` question
   can name it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `verification-handoff.sh` emits `verification_probe` per member and `probe`/`probe_member` at the top level.
- `handoff`, `reason`, `member`, `missing` and `members[]` membership are byte-identical to before for every existing declaration.
- A handoff with no probe reports an empty string, never an absent key.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — rows over a declared probe, a handoff with no probe, and the derived `.claude/` case.
- The reader run against this repository's own standing declarations, output compared field by field with the pre-change run.

**Gate** — what must pass before approval:

- No probe is executed anywhere in this ticket.

## Considerations

- Reading a command out of frontmatter is not running it; keeping those two tickets apart is
  deliberate, so the reader stays a pure read and the execution has its own bounds.

## Final Report

**Outcome**: implemented.

`verification-handoff.sh` — still the **one** reader of the field — now reports three new facts per
member and once for the unit: `probe` (the command, verbatim, or empty), `measurable` (a probe was
declared), and `unmeasured` (a non-empty declaration carrying no probe).

**It does not run the probe, and that separation is the point.** This reader is called at route
time, inside `/moderate`, and by anything that wants to know what a unit declares; a reader that
executed a command every time somebody asked what a ticket says would be a different and much larger
thing. Running it is the claim-time runner's job.

**No verdict changed.** `handoff`, `reason`, `member`, `members[].verification_handoff` and
`missing` are byte-identical for all three input classes, proved directly: a probe declaration, a
prose declaration and an absent one each still answer exactly what they answered before.

**The suite proves the reader is a reader**: the probe under test is `touch <canary>`, and the
assertion is that the canary does **not** exist after the read.

**Verified**: `node scripts/test-workflow-scripts.mjs`.
