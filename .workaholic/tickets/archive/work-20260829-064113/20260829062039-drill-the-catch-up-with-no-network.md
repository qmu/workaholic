---
created_at: 2026-08-29T06:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# Drill the catch-up with no network

## Overview

PROPOSED. `scripts/e2e/loop-drill.sh verify-catch-up` over a git-backed fixture and a bare
local origin: a mechanical conflict caught up and delivered, a content conflict refused with
the branch byte-identical, a foreign claim untouched, a scan-held pull request never caught
up, a second run a no-op.

**A breaker row that fires the moment the bound is widened** to a claim this identity does not
hold — the drill must be provably able to fail, on the behaviour rather than on a return shape,
so a refactor that keeps the shape and loses the bound still fires it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill harness; operator tooling outside the plugin.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame table.
- The ticket-1 fixture — reused rather than rebuilt.

## Implementation Steps

1. Add the `verify-catch-up` verb, composing the ticket-1 fixture over a bare local origin
   with the transport stubbed. No network at any point.
2. Drill five rows: mechanical caught up and delivered; content refused, branch byte-identical;
   a foreign claim untouched; a scan-held pull request never caught up; a second run a no-op.
3. Add the breaker row: wire the identity bound open and prove the drill fails. Write it
   against the **behaviour**, not the output shape.
4. Register the verb in `docs/loop-drill-runbook.md` with its blame table rows.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Five rows plus a breaker, all with no network and no `gh`.
- The breaker is proved able to fail against a deliberately widened bound.
- Nothing outside the fixture is written.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-catch-up`

**Gate** — what must pass before approval:

- The drill is green on the finished mission and red on the deliberately broken seam.

## Considerations

The drill assumes the server's full `gh` and `qfs`, like every other verb, and ships to no
other agent. Keep it outside the plugin.

## Final Report

Development completed as planned. `sh scripts/e2e/loop-drill.sh verify-catch-up` runs nine
load-bearing rows over a bare local origin with `gh` stubbed on `PATH` — no network at any
point, and the first row proves it by asserting the stub is what `gh` resolves to. It is
dispatched by its verb, named in the usage line, documented in `docs/loop-drill-runbook.md`
as §5k-bis with a row-by-row blame table, and pinned in `scripts/test-workflow-scripts.mjs`
by the same four checks every other verify target carries.

Five drilled rows plus the breaker, as asked: a mechanical conflict caught up, validated and
pushed with the higher semver winning the manifest collision; a `content` conflict refused with
the branch **byte-identical**; a scan-held pull request never caught up; a second run a no-op;
and the refused conflict reaching its claim holder exactly once while the caught-up unit draws
no question. Two more rows ride along — the no-network proof and the checkout-untouched proof.

**The breaker is written against the behaviour and is proved able to fail.** It hands the writer
a claim this identity does not hold and asserts on the **branch tip**, so a refactor that keeps
the JSON shape and loses the bound still fires it. Verified by dropping `foreign_identity` from
the verdict gate and neutering the `not_my_claim` comparison: the drill merged into
`work-20260101-000004` and pushed it, failing exactly that row while the other eight stayed
green — then restoring both turned it green again.

The ticket asked to reuse the ticket-1 fixture. The hermetic fixture lives in
`test-workflow-scripts.mjs` (Node) and the drill is POSIX shell operator tooling outside the
plugin, so it is reused as a **shape** rather than as code: the same four-unit stranding, the
same conflict classes, the same stubbed transport. Sharing the builder across the two languages
would mean a third home for one fixture.

### Discovered Insights

- **Insight**: `.workaholic/stories/` holds only the previous unit's story, so checking `main`
  out removes the file and git prunes the empty directory.
  **Context**: Without an explicit `mkdir -p` the redirect fails silently, the branch carries no
  story, and every claim reads `report_incomplete` instead of the drained state the whole drill
  is about. It cost two red rows that looked like seam failures and were fixture failures; the
  trap is named in the runbook so the next fixture author does not pay for it again.
- **Insight**: A breaker row asserted on a return shape survives the refactor it exists to
  catch.
  **Context**: Asserting `reason == "foreign_identity"` would still pass if the gate moved
  *after* the merge and push. Asserting the colleague's branch tip did not move cannot.
