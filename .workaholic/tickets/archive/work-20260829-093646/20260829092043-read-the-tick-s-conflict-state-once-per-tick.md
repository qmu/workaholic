---
created_at: 2026-08-29T09:20:43+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
claim: work-20260829-093646
---

# Read the tick's conflict state once per tick

## Overview

PROPOSED. `moderate/reference/workflow.md` states of step 6: *Reads `pulls-state.sh`, as
step 4 does — **resolved once per tick, used twice***. The implementation does not hold
that contract: `step-merge-conflicts.sh:48` and `step-stuck-prs.sh:63` each call
`pulls-state.sh` themselves, so the tick resolves it **twice**, over two separate rounds of
`GET /repos/{slug}/pulls/{n}`.

That is not merely wasteful, it is a correctness defect, because the field the whole reading
keys on is **computed lazily by GitHub**: `mergeable` is `null` until a background merge job
finishes, and requesting the pull request is what schedules it. So the first resolution can
answer `mergeable: null` → `blocked_by: unknown` for a branch the second answers
`mergeable: false` → `blocked_by: conflict`. Two steps of one tick then state different
things about the same seven pull requests, and neither is wrong about what it read.

**Measured** (tick `20260829-085055`, issue #710): `merge-conflicts` reported
`none conflicted` and `stuck-prs` reported four conflicted — #622, #625, #633, #688 — over
the same open set, in the same tick. The finding this ticket's mission grew from names the
disagreement in its own words: *two readings of one fact drifting is exactly the shape this
repository repairs by giving the fact one reader.*

The fact already has one reader. What it does not have is **one resolution**: this ticket
makes `run.sh` resolve `pulls-state.sh` once and hand the same JSON to both steps, so the
two cannot disagree by construction rather than by timing.

Reported, never acted on: nothing here rebases, merges or touches a claim.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/moderate/scripts/pulls-state.sh` — the one reader; its
  `blocked_by` rule is correct and is **not** what this ticket changes.
- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — step 4, line 48:
  resolves the state itself today.
- `plugins/workaholic/skills/moderate/scripts/step-stuck-prs.sh` — step 6, line 63: resolves
  it again.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the step list, and the only place a
  per-tick resolution can live.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — steps 4 and 6, where the
  *resolved once per tick, used twice* sentence already stands and would become true.

## Implementation Steps

1. **Reproduce before repairing.** Over a stubbed transport, serve the same pull request as
   `mergeable: null` on the first read and `mergeable: false` on the second, run the two
   steps in `run.sh`'s order, and capture the disagreement — `none conflicted` from step 4
   beside a `conflict` row from step 6. That failing capture is what the fix must flip.
2. **Localize.** Confirm the two call sites (`step-merge-conflicts.sh:48`,
   `step-stuck-prs.sh:63`) are the only resolutions, and that `pulls-state.sh` itself is
   deterministic given one round of responses — the drift is in the number of resolutions,
   not in the classifier.
3. Resolve `pulls-state.sh` **once**, in `run.sh`, before either step, and pass the result
   to both — a path or the JSON on a named option, whichever keeps each step runnable on
   its own. A step invoked without it falls back to resolving for itself, so neither script
   stops working standalone and no test harness has to learn a new entry point.
4. Keep both steps' outputs byte-identical for an unchanged input: the summaries, the
   `stuck:<digest>` key, the `headline` derivation and step 4's silence are all untouched.
   This ticket changes **when** the state is read, never what is concluded from it.
5. Make the reference's sentence true rather than restating it: step 4's and step 6's
   **Reads** lines name the shared resolution, and the drift this repairs is recorded where
   the contract is stated.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One tick performs **one** `pulls-state.sh` resolution; steps 4 and 6 read the same bytes.
- The reproduction from step 1 no longer disagrees: both steps report the same conflict set
  for the same tick, whatever the transport answers on a second read.
- Each step still runs standalone, resolving for itself when the shared state is absent.
- For an unchanged input, both steps' JSON is byte-identical to today's — the
  `stuck:<digest>` key included, so no post changes frequency or threading.
- Nothing rebases, merges, closes or touches a claim.

**Verification method** — the commands/tests/probes that prove them:

- The stubbed-transport reproduction from step 1, as a hermetic case in
  `scripts/test-workflow-scripts.mjs`: it fails on today's tree and passes after.
- A count of the transport's pull-request reads per tick, asserted to have halved.
- A byte-for-byte diff of both steps' output over a fixed fixture, before and after.
- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/build.mjs`,
  `node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The hermetic case is written **against the disagreement**, not against a return shape: a
  refactor that keeps the shape and restores the second resolution must still fail it.

## Considerations

- **The classifier is not the suspect.** `pulls-state.sh`'s `blocked_by` rule maps
  `mergeable == false` and `mergeable_state == dirty` to `conflict` and `mergeable == null`
  to `unknown`, which is right. Changing it would be repairing the wrong thing.
- **`unknown` still renders as `none conflicted` after this ticket.** One resolution removes
  the *disagreement*; it does not make step 4 honest about a state it could not read. That
  is the sibling ticket `20260829092046-tell-an-uncomputed-mergeability-from-none-conflicted.md`,
  and neither ticket subsumes the other — with only this one, a single shared `unknown`
  reading still reports "none conflicted" in one voice instead of two.
- `reconcile-candidates.sh` bounds its own reads separately and is deliberately out of
  scope: it answers a different question over merged and closed pull requests.

## Final Report

Development completed as planned, and the disagreement was reproduced before anything was
repaired. The hermetic case serves the same pull request as `mergeable: null` on the first
round of per-pull reads and `mergeable: false` on every round after; against two independent
resolutions the two steps contradict each other, and a per-round counter proves the tick now
makes **one** round rather than two.

**The cache lives in the one reader, not in its callers**, and that is the decision worth
recording. `run.sh` resolves once before the step loop and names the file in
`WORKAHOLIC_TICK_PULLS_STATE` — the seam `WORKAHOLIC_TICK_REPORTS` already established, an
environment variable rather than a third flag so the step invocation stays uniform — and
`pulls-state.sh` is what consults it. So **both steps are byte-identical**: their summaries,
the `stuck:<digest>` key, the `headline` derivation and step 4's silence could not have moved,
which is stronger than asserting they did not. "Resolved once per tick" becomes a property of
the reader rather than a sentence each caller must remember.

Three bounds ride with it. The cache is keyed on the `--limit` it was resolved at, so a caller
asking for a wider read resolves afresh rather than being served a silently truncated answer. A
**failed** resolution is never cached — `pulls-state.sh` reports its own degradation, and
serving that from a cache would make one transport hiccup the tick's answer for every consumer.
And the resolution is gated on the same `--only`/`--skip` arithmetic the loop applies, so a tick
narrowed to a step that never reads pull requests pays for no read.

The test asserts **agreement**, not a particular verdict: which round the tick sees is the
transport's business, and that the two steps see the same one is the contract. With this ticket
alone both now read the shared `unknown` and both name it — exactly what the sibling ticket's
Considerations predicted, and why neither subsumes the other.

### Discovered Insights

- **Insight**: `mergeable` is computed lazily and *requesting* the pull request is what
  schedules the job, so an extra read is not merely wasteful — it changes the answer.
  **Context**: Any future consumer of `pulls-state.sh` inherits this. A second resolution in a
  third step would reintroduce exactly the drift measured on tick `20260829-085055`, which is
  why the cache is in the reader rather than in the two callers that happen to need it today.
- **Insight**: Putting the cache in the reader is what makes "both steps are unchanged" provable
  rather than asserted.
  **Context**: The alternative — teaching each step to accept shared state — would have needed a
  byte-for-byte output diff per step to establish the same property.
