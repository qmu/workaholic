---
created_at: 2026-08-27T11:25:28+00:00
status: done
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

## Final Report

Development completed as planned. `verify-revision` runs over local fixtures with the transport
stubbed and **no network**: the strategy half is local files, the publish half a local bare
origin with `gh` on `PATH`. Eleven load-bearing rows. The three successes are drilled separately
— a date moved (both the frontmatter and the `Target:` line, one recorded line), an aim sharpened
through the stdin form, an assignee changed — each asserting the revised part changed, every
other field byte-identical and the `## Schedule` line appended in order. The refusals are drilled
by name with the artifact's hash asserted untouched: `no_revision`, a floor breach
(`no_assignees`), an immutable field (`bad_option`), a closed direction (`not_active`), plus the
no-op appending nothing. The exemption is drilled beside them: a publish whose tree touches
`.workaholic/strategies/` reports `strategy_touching` and stays open with
`WORKAHOLIC_AUTO_MERGE=1` set — the stub answers a **successful** merge on purpose, so the
refusal cannot pass for the wrong reason.

**The deliberately broken row is `revision_immutable_field_unreachable`, and it was observed
failing**: adding a `--status` case to `amend.sh`'s option loop turned exactly that row red
(10 passed, 1 failed) while every other row stayed green, and the writer was restored
byte-identical. The drill was also run with every proxy variable unset and passed unchanged,
which is what makes the no-network claim a measurement rather than an assertion. Registered in
`docs/loop-drill-runbook.md` (§5l-bis, the summary table, and a failure-reason → file blame row
for each of the eleven) and in `CLAUDE.md`'s drill enumeration.

### Discovered Insights

- **Insight**: a row that only checked the refusal *word* would pass a writer that wrote and
  then rolled back, so every refusal row asserts the artifact's hash across the call.
  **Context**: "a refusal never wrote" and "a refusal left no net change" are different
  contracts, and only the first is what this artifact needs.
- **Insight**: the drill's own `revision_writes_nothing` row is what catches a fixture that
  escaped its temp directory — every path here is under `mktemp -d`, including the publish
  origin, so the drill can be run from a dirty checkout without confusing its own result.
  **Context**: the same shape `verify-retire` uses; worth copying rather than re-deriving.
