---
created_at: 2026-08-27T11:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Drill the strategy revision end to end with no network

## Overview

PROPOSED. Every act this loop performs on the direction layer is drillable on demand
rather than by waiting for a tick — `verify-direction-health`, `verify-propose`,
`verify-retire`, `verify-delivery-retry`. The revision path earns the same treatment, and
for a sharper reason: it is the first write into `.workaholic/strategies/` a machine
makes on the operator's behalf, and its whole safety rests on a set of refusals.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the new `verify-revision` subcommand; read
  `verify-direction-health` and `verify-retire` first for the fixture and stub shape.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file
  blame table this drill contributes to.
- `plugins/workaholic/skills/strategy/scripts/amend.sh` — the subject.

## Implementation Steps

1. Add `verify-revision` to `scripts/e2e/loop-drill.sh`, over a local fixture with the
   transport stubbed and **no network**.
2. Drill the three successes separately: a date moved, an aim sharpened, an assignee
   changed. Assert the file after each — the revised part changed, every other field
   byte-identical, the `## Schedule` line appended.
3. Drill the refusals, each by its own name and each asserting the file is untouched: a
   closed direction (`not_active`), an immutable field, a floor breach, and an ask naming
   nothing revisable (`no_revision`).
4. Drill the exemption: a publish whose tree touches `.workaholic/strategies/` does not
   merge even with `WORKAHOLIC_AUTO_MERGE=1`.
5. Include a **deliberately broken seam** that proves the drill can fail — a row the
   drill is expected to catch — as `verify-identity-handoff` and `verify-retire` both do.
   A drill that cannot fail proves nothing.
6. Register it in `docs/loop-drill-runbook.md` with its failure reasons and the file each
   blames, and in `CLAUDE.md`'s drill enumeration.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-revision` passes with no network available.
- Each of the four refusals is drilled by name with the artifact asserted untouched.
- The deliberately broken seam is observed failing.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-revision`
- The same run with the network removed, to prove the stubbing is real.

**Gate** — what must pass before approval:

- The drill is green, the broken seam was seen red, and the runbook names it.

## Considerations

- The drill is operator tooling outside the plugin and assumes the server's full `gh` and
  `qfs`; it ships to no other agent. Keep the plugin's own hermetic suite the place where
  `amend.sh`'s unit behaviour is pinned, and keep this drill about the path.
