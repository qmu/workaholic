---
created_at: 2026-08-31T20:34:53+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Reproduce a superseded branch that still holds work

## Overview

PROPOSED. The ask reports a failure whose destructive half has never actually fired — a 403
has been refusing the delete — so the first thing this mission owes itself is the failing case
made real and offline, where deleting costs nothing. Every later ticket is judged against this
reproduction, and no repair may be designed before it exists.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_superseded`, the
  derivation under test, and `claims_archived_on_base` / `claims_mission_landed` beneath it.
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the destructive consumer.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the CI consumer,
  whose `not_on_base` bound re-derives `claims_superseded` and therefore inherits the same gap.
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate reader.

## Implementation Steps

1. Build the measured shape offline: a base carrying a unit's tickets archived under **another
   branch's** directory, and the claim branch itself still holding a file that is on no other
   ref. Both the batch grain and the mission grain, since the two take different routes
   through `claims_superseded`.
2. Record what each layer answers today, verbatim: `claims_superseded`, the row's verdict from
   `list-claims.sh`, `list-retirable-claims.sh`'s candidate set, and
   `delete-retired-claim-branch.sh`'s `not_on_base` re-derivation.
3. Confirm the inversion the ask names: that `delete-retired-claim-branch.sh`'s `not_on_base`
   bound is a re-derivation of the same proof rather than an independent diff test, so it
   refuses nothing this gap lets through.
4. Record the cost of the proposed term — one `merge-base` plus one `diff --quiet` per branch —
   measured against the scan's existing per-claim cost, so the later ticket knows whether it
   can afford to run per row or only at the act.
5. Write the finding into the mission's `## Changelog` as one line.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reproduction runs offline with no credential and no network call.
- It demonstrates a branch holding unmerged content being offered as retirable, at both grains.
- Each layer's current answer is recorded before any repair lands.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The reproduction, run twice, giving the same answers.

**Gate** — what must pass before approval:

- No behaviour change ships in this ticket. It measures; it repairs nothing.

## Considerations

- The 403 masking the delete is load-bearing to how this reads in production and must not be
  relied on. The reproduction deliberately lets the delete succeed, which is the only way to
  see what would be lost.
- A branch may hold work that is genuinely disposable — a resume commit, a heartbeat, a claim
  commit. The reproduction must include one of those too, or the later ticket will not know
  which non-empty diffs are real work and which are the protocol's own bookkeeping.
