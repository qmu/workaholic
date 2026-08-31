---
created_at: 2026-08-31T20:34:53+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Refuse to retire a branch that still holds work

## Overview

PROPOSED. The repair. `claims_superseded` gains the diff term from the previous ticket, so the
proof means what its header already claims — the branch can never land and holds no work — and
neither destructive consumer can reach a branch that still carries content. The change must
only ever **remove** a `superseded`, never add one: that is the direction that matters when a
proof gates a destructive act.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_superseded`, both grains.
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — Act 1/2/3 in the container.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the CI act, whose
  `not_on_base` bound re-derives the proof and therefore inherits the fix for free.
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate reader.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `resurveyed[]`, the non-destructive
  consumer, which must be checked for what the narrowing does to it.

## Implementation Steps

1. Add the diff term to `claims_superseded` at **both** grains: the batch grain's every-ticket-
   archived test and the mission grain's `claims_mission_landed` / merged-lookup route.
2. An **unanswerable** diff reading answers `false` — not superseded. A degradation must never
   license a delete; this is the same direction the merged lookup's `unanswerable` already
   takes.
3. Re-derive at the moment of the act, not once per scan, in both `retire-claim.sh` and
   `delete-retired-claim-branch.sh`. Both already re-derive the proof where they act; the new
   term rides that same re-derivation rather than adding a second place it can go stale.
4. Walk every consumer of `superseded` and record what the narrowing does to each: `claim.sh`
   (which skips a superseded row so a fresh claim goes through), `plan-units.sh`'s
   `resurveyed[]`, `retry-undelivered.sh`, `catch-up-claim.sh`, `list-retirable-claims.sh`, and
   the `stalled-units` / `retire-claims` filter pairing in `/moderate`. A row that stops being
   `superseded` becomes something else, and each consumer must be shown to behave correctly
   under that.
5. Measure the added cost against the reproduction's numbers and state it: the scan's most
   expensive gate is already the archive listing, and this adds a per-branch tree read.
6. Update `drive/reference/claims.md` and `CLAUDE.md` in the same commit — the proof's meaning
   is changing, and the *Proofs and judgements* statement must say what it now proves.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A branch whose tickets landed elsewhere and which still holds a file is **not** `superseded`,
  at both grains, and reaches neither destructive act.
- A branch genuinely empty against the base is still `superseded` and still retires, with the
  container and CI paths behaving as they do today.
- An unanswerable diff reading yields `false`, never `true`.
- Every named consumer has its behaviour under the narrowing recorded.

**Verification method** — the commands/tests/probes that prove them:

- The reproduction from the first ticket, now refusing the delete.
- Hermetic rows in `scripts/test-workflow-scripts.mjs` per grain and per consumer.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The change can only remove a `superseded`, never add one — demonstrated, not asserted.
- No new verdict word is emitted by `lib/claims.sh` in this ticket (the stranded state is the
  next ticket's).

## Considerations

- Narrowing a proof strands rows somewhere else: a claim that stops being `superseded` will
  read as something, and if that something is `claim_active` or `stale` it will be re-offered
  or reported oddly. Step 4 exists because that is where the real risk of this ticket lives,
  not in the diff term itself.
- `superseded` is one of only two proofs in the protocol. Anything that makes it *harder* to
  establish is safe; anything that makes it easier is not. Keep that asymmetry visible in the
  header so a later change cannot quietly reverse it.
