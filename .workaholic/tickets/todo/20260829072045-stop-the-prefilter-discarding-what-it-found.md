---
created_at: 2026-08-29T07:20:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Stop the prefilter discarding what it found

## Overview

PROPOSED. Repair both hops of `attributed-work.sh` so a batch that matches nothing costs
nothing: the accumulated candidate list survives, and hop 2's `via_mission:` attribution
comes back with it. The prefilter/confirm split is kept intact — the `grep` still decides
only *worth reading* and the relation reader still decides attribution — so this ticket
changes which candidates reach the confirm loop and nothing about how attribution is
decided.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/keep-serving.md` — a reader that degrades must not degrade silently

## Key Files

- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — hop 1's `cand1` and
  hop 2's `cand2`; the two call sites of the shape
  `xargs grep -lFf "${TMP}/patterns" < "${TMP}/corpus" … || : > "${TMP}/cand1"`.
- `scripts/test-workflow-scripts.mjs` — the case written in the previous ticket, which must
  turn green here.
- `outputs/workflows/` — regenerated, never hand-edited.

## Implementation Steps

1. Re-run the previous ticket's case and confirm it still fails, so the repair is measured
   against a live failure rather than a remembered one.
2. **Replace the truncating `||` on both hops.** The accumulated output must survive a batch
   that matched nothing. Prefer the smallest change that keeps the prefilter a prefilter —
   for example appending across batches rather than redirecting the whole `xargs` run, so a
   per-batch exit is not the whole walk's exit.
3. Apply the identical shape to **both** hops. Hop 2 carries every ticket's `via_mission:`
   attribution, so its loss is the larger one and it must not be repaired only in passing.
4. **Do not widen the prefilter's job.** It still answers *worth reading*; `read-feedback-
   relation.sh` and `read-relation.sh` still decide attribution, and neither gains a second
   parser here.
5. Leave the honest-zero paths alone: an empty corpus still reports `no_citing_artifacts`
   through the existing `emit_empty`. Distinguishing *found nothing* from *could not look* is
   the next ticket and is deliberately not started here.
6. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The previous ticket's case passes, at both hops.
- A batch that matches nothing no longer discards candidates earlier batches found.
- A genuinely empty result is byte-identical to today's output — nothing that reported
  `no_citing_artifacts` honestly starts reporting a citation.
- The prefilter/confirm split is unchanged: no attribution decision moved into the `grep`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- On this checkout: `attributed-work.sh an-autonomous-improvement-loop-run-by-the-routines`
  reports its citing missions instead of `no_citing_artifacts`.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `Outputs Freshness` shows no diff after the rebuild.
- No behaviour change for a corpus that fits in one batch, proved by the existing cases.

## Considerations

- The tempting one-liner is to drop the `|| :` entirely, which under `set -e` turns a
  no-match batch into a fatal error — the opposite failure. Whatever shape is chosen must
  keep a no-match batch a **success**.
- `grep` exiting 2 or more is a real failure and must not be swallowed by this repair either;
  naming that case is the next ticket's subject, and this one must not foreclose it.
