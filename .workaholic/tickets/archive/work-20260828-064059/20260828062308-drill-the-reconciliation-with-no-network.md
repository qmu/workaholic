---
created_at: 2026-08-28T06:23:08+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: reconcile-a-stale-thread-with-the-unit-s-real-state
merge_policy:
verification_handoff: 
---

# Drill the reconciliation with no network

## Overview

Every reading this loop acts on is drilled with no network and one deliberately broken row —
`verify-return-path`, `verify-handoff-question`, `verify-base-health`, `verify-retire`. This
reconciliation posts into a person's thread, which is the one class of act where a duplicate is
paid for by a human reading it twice, so it gets the same treatment: a drill that proves the
bounds, and a breaker row that fails the moment the seam is wired wrong.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/verification.md` — a property proved on demand, not by waiting for a tick

## Key Files

- `scripts/e2e/loop-drill.sh` — where `verify-reconcile` lands, beside the existing verbs
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file blame table
- `plugins/workaholic/skills/moderate/scripts/step-thread-reconcile.sh` — the step under drill
- `scripts/test-workflow-scripts.mjs` — the hermetic half
- `CLAUDE.md` — the drill list

## Implementation Steps

1. Add `verify-reconcile` to `scripts/e2e/loop-drill.sh`, over local fixtures with the Slack and
   GitHub transports stubbed and **no network**.
2. Drill the rows that matter:
   - a merged handed-off unit whose thread's last word is `🟡 Handoff` → the reply is posted, once
   - the **same tick run twice** → the second posts nothing (the read-before-write is structural)
   - a thread already ending in `🟢` → never touched
   - a unit with **no thread found** → nothing posted, reported by name
   - a closed-unmerged unit → the closed form, not the merged one
   - an unreadable transport → reported, nothing posted, and never rendered as a thread nobody answered
3. Assert the bounds mechanically: at most two search queries per candidate, no channel history
   call, and the candidate cap honoured with the remainder reported.
4. Assert what it never does: no merge, no close, no branch, no claim touched, and no write into
   the tree but the tick's own log line.
5. **Add a breaker row** — wire the candidate reader at the **channel** instead of the repository,
   and assert the drill fails. A drill that cannot fail proves nothing; this is the row that
   catches the design being inverted back to a channel scan.
6. Document the verb in `docs/loop-drill-runbook.md` with its blame table, and add it to
   `CLAUDE.md`'s drill list in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-reconcile` passes with no network and no live credential
- Every row above is covered, including the second tick posting nothing
- The breaker row fails when the reader is wired at the channel
- The verb is documented in the runbook with its blame table and named in `CLAUDE.md`

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-reconcile`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Both commands pass, and the drill is proved able to fail by the breaker row
- `outputs/` regenerated and clean

## Considerations

- The drill runs after the other four tickets by necessity — it is the mission's proof, and it is
  what the acceptance item about the bounds is checked against.
- Keep the fixtures local: the drill assumes the server's full `gh` and `qfs` like its siblings and
  ships to no other agent, which is why it lives outside the plugin.

## Final Report

Development completed as planned.

`sh scripts/e2e/loop-drill.sh verify-reconcile` runs over a git-backed fixture under the OS temp
dir with a `gh` stub on `PATH` and **no network**: fifteen load-bearing rows, all passing. The stub
answers only the calls the reader makes and fails loudly on anything else, and the drill asserts the
stub is what `gh` resolves to rather than assuming it. The Slack half is fixture data on purpose —
what is under test is which items are named and what bar the reply is held to, not the transport.

Rows: the hand-merged unit named with its stems, its pull request and by-whom-and-when; a
closed-unmerged unit reading `closed` and never `merged`; both catalog shapes present with the
template's copies matching; the bar classifying four fixture threads (`🟡` → post, `🟢` → never
touched, an already-reconciled thread → never touched, no thread → nothing to correct); the
two-query bound with no channel history and no window; case 4 refused by name; the six not-posted
reasons and the one-outcome rule; the cap honoured with the remainder reported; a second tick
handing back nothing; a refused read named rather than rendered as quiet; neither script merging,
closing, branching, committing or touching a claim; the tree carrying nothing but the tick's own log
line; and the checkout byte-identical afterwards. The **breaker row** wires the candidate reader at
the **channel** — its `gh-rest.sh` replaced by one that returns channel messages — and the drill
fails there, which is what proves it can fail.

The verb is documented in `docs/loop-drill-runbook.md` §5r with its blame table, named in
`CLAUDE.md`'s drill list, and pinned in the suite (present, dispatched, in the usage line,
documented, and the breaker row named in both places).

### Discovered Insights

- **Insight**: the drill found a real defect in the reader — **a tab is IFS whitespace**, so an
  empty `merged_at` collapsed and shifted `closed_at` into it, and every pull request closed without
  merging read `merged`.
  **Context**: that is the single distinction the two reply shapes exist to draw, and the hermetic
  test had missed it because it only asserted the row was *read*, not what state it read as. The jq
  now emits a `-` sentinel for the two fields whose emptiness is meaningful, both stubs emulate it,
  and both proofs now assert the state.
- **Insight**: a closed-unmerged unit is invisible to every **local** source, so `⚫ Closed` was a
  shape nothing could ever reach.
  **Context**: no merge commit, no story on the base, nothing archived. The reader now asks for that
  pull request's own changed files — one call, **only** for a candidate the tree could not answer,
  bounded by `--limit` like every other per-pull read — and a mission published by an earlier merge
  resolves it. Building the drill's fixture honestly (a branch that is genuinely never merged) is
  what surfaced this; a fixture that merged the "closed" unit would have hidden it.
