---
created_at: 2026-09-03T07:17:26+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: pay-only-the-operative-cost-on-every-tick
merge_policy:
verification_handoff: 
---

# Say nothing at length on a tick that did nothing

## Overview

The command asks for a per-loop line every tick. The majority of this session's ticks had
nothing to say and still printed four to six lines of `still_running` / `not_due`. The principle
is already written in this plugin — `/moderate`'s post gate makes an idle hour silent — and the
tick's own terminal report does not follow it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §3, the report's ceiling
- `plugins/workaholic/skills/moderate/SKILL.md` — the post gate this borrows its principle from

## Implementation Steps

1. Rewrite §3 so a tick that swept nothing, reaped nothing and spawned nothing reports **one**
   line. §3 already says that in words; the per-loop bullet contradicts it, so the two are
   reconciled rather than a new rule added.
2. Keep every line a tick that *did* something owes: per message, per loop, the dirty checkout,
   and every named degradation. Quiet is the only case that shrinks.
3. A degradation is never quiet: `channel_unreadable`, `sweep_dedup_unreadable`,
   `cadence_unreadable` and `checkout_dirty` are reported on an otherwise silent tick.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick that swept, reaped and spawned nothing reports one line.
- A tick that did anything reports exactly what it reported before.
- A degradation is reported even on an otherwise quiet tick.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/infinite-development.md` §3 against the three conditions.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No degradation was made quiet by this change.

## Considerations

The failure to avoid is a quieter loop that is indistinguishable from a stopped one — the
outage this repository has measured twice. That is why the degradation clause is an acceptance
criterion and not a note.
