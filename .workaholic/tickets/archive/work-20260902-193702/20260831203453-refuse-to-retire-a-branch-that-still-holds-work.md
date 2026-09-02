---
created_at: 2026-08-31T20:34:53+00:00
status: done
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

## Final Report

Development completed as planned. The **derivation** had landed with the repair (2026-09-01,
issue #788) — `claims_superseded` is three-valued at both grains, an unanswerable emptiness
answers `stranded`, and both destructive consumers re-derive it at the moment of the act. What
this ticket owed and did not have was **step 4 and the verification**: the walk over every
consumer, recorded, and hermetic rows proving the narrowing only ever *removes* a `superseded`.

- **The consumer walk is now a table** in `drive/reference/claims.md`, *What the narrowing did to
  every consumer of `superseded`*, one row per consumer with its behaviour under each verdict.
  It is recorded rather than re-derived so a later consumer is **added to the table** rather than
  discovered by a reader wondering what happens to it. `catch-up-claim.sh` is stated honestly:
  it carries **no `stranded` bound of its own** and relies on its caller never offering one,
  which is safe only because its act merges the base *into* the branch and deletes nothing.
- **Hermetic rows** pin the derivation at both grains (`stranded` on a branch holding an orphaned
  file, `superseded` once that file is gone, `stranded` on an unreadable tip) and every consumer
  with observable behaviour: `plan-units.sh` excludes `claimed_stranded` and never returns the
  work through `resurveyed[]`, `list-retirable-claims.sh` offers no candidate, and `claim.sh`
  refuses `already_claimed` rather than stepping over the row as it does for `superseded`.
- **The asymmetry is demonstrated, not asserted** (the gate's own words): the same fixture reads
  `superseded` before the orphaned file exists and `stranded` after, so the change is visibly a
  narrowing. The offline drill added by this mission's last ticket makes the same point
  destructively — with the term reverted, both work-holding branches came back
  `remote_branch_deleted: deleted`.

### Discovered Insights

- **Insight**: The emptiness reading had to capture `git diff --quiet`'s status **inside an
  `if`**, not after a bare call. `lib/claims.sh` is sourced by scripts running under `set -e`,
  where the ordinary *this branch differs* answer (exit 1) aborts the caller — the function's
  subshell died, its output was empty, and `delete-retired-claim-branch.sh` answered
  `emptiness_unanswerable` for **every** non-empty branch. It still refused the delete, so no
  safety property moved, but a person would have been sent after a reading that failed rather
  than a branch that holds work. Caught by two existing rows in `scripts/test-workflow-scripts.mjs`
  within the same branch.
  **Context**: Any future helper in this library that wants a command's exit status must not
  write `cmd; rc=$?` — the whole file is sourced into `set -e` callers.
- **Insight**: A hermetic row over the **mission grain** must seed a ticket that *names the
  mission* at the branch tip. Without one `claims_mission_landed` cannot answer locally and the
  verdict falls through to `claim-merged.sh`, the protocol's one network read — so a row written
  without it silently measures the transport's absence instead of the verdict.
  **Context**: The same trap cost two red rows here and one in the drill; both fixtures now carry
  the ticket and say why in a comment.
