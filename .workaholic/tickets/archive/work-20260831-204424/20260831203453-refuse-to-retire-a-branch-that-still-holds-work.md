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

Development completed as planned. `claims_superseded` gains the diff term at both grains,
composed last, and neither destructive consumer can now reach a branch that still carries
content of its own.

**The change can only remove a `superseded`, never add one** — demonstrated rather than
asserted: the term is an extra conjunct on each of the three existing `printf 'true'` points
(`claims_mission_landed`, the merged lookup, and the batch grain's every-ticket test) and
appears nowhere else, and an `unanswerable` reading answers `false`. The reproduction shows
both directions in one run: the two branches holding content are refused and survive, the
branch holding only a claim commit and a heartbeat still retires.

**Two corrections the fixtures forced, both of which make the reading more nearly right:**

- **A deletion holds nothing.** Both diffs run under `--diff-filter=d`, so a path the branch
  removed is not counted. Without it a unit that drained its queue by moving tickets out of
  `todo/` read as holding every one of them — a deletion rendered as work.
- **What is subtracted is the loop's own bookkeeping on that branch**, not the claim stamp
  alone: the stamped artifacts (matched by exact path *and*, inside the queue directory, by
  filename, because `migrate-todo-owners.sh` gives one artifact two paths across its
  convergence), `stories/<branch>.md`, `tickets/archive/<branch>/`, and the generated OKF
  indexes through `conflict_class_generated_path` — the one rule that already says what is
  generated, read rather than restated, and sourced inside the command substitution so no
  claims consumer gains those functions.

**Every consumer, and what the narrowing does to it:**

| Consumer | Under the narrowing |
| -------- | ------------------- |
| `retire-claim.sh` | gates on `verdict != "superseded"`; a stranded row is refused `not_superseded:<verdict>`. |
| `delete-retired-claim-branch.sh` | its `not_on_base` bound re-derives `claims_superseded`, so it inherits the fix with no change of its own — proved in the reproduction and in a hermetic row. |
| `list-retirable-claims.sh` | takes only `superseded_only` units, so a stranded branch is no longer a candidate. |
| `claim.sh` | skips a `superseded` row so a fresh claim goes through; a stranded row is no longer skipped, so the unit is refused under whatever verdict it now reads. No work is lost by that: the archive test passed, so the unit's tickets are already on the base and the queue holds nothing to re-drive. |
| `plan-units.sh` `resurveyed[]` | takes only `superseded`, so a stranded row's members are excluded under its new reason instead of being resurveyed — again over work already archived on the base. |
| `retry-undelivered.sh` | refuses every verdict but `report_undelivered` by name; unchanged in kind. |
| `catch-up-claim.sh` | keys on `report_undelivered` / `queue_drained`, both of which a stranded row can now reach — correct: a branch that still holds work is one worth keeping current with the base. |
| `/moderate` `retire-claims` | no longer sees the row, so it neither acts nor asks about it. |
| `/moderate` `stalled-units` | filters `superseded` out of its candidates, so a stale stranded branch now falls into its question instead. **This is the narrowing's one loose end**, and it is the next ticket's: the state has no word yet, so it is asked about under a heading that says the wrong thing. |

**Cost**, measured on this repository (1156 archived ticket paths on `origin/main`): the term is
one `merge-base` plus two `diff --name-only` calls, ~8.3 ms per claim against the archive
listing's ~4.0 ms — roughly twice the scan's existing worst gate. Composed **last**, so it runs
only where every cheaper condition already answered `true`.

Documents updated in the same commit: `drive/reference/claims.md`'s *Proofs and judgements*
row for `superseded` now states both halves, and `CLAUDE.md` says what the proof now proves.

### Discovered Insights

- **Insight**: three of the suite's existing fixtures encoded the old, narrower contract, and
  each one taught the reading something.
  **Context**: `testSupersededClaimIsNotOffered` said in its own comment that *the signal
  cannot be "the diff is contained in the base"* because a hand recovery lands **refined, not
  verbatim** — which is exactly why the branch's own archive directory is subtracted rather
  than compared. The declared-handoff fixture exposed the two-paths-per-artifact problem the
  queue migration creates. And `testMergedClaimIsNeverResumable` was telling the lookup a pull
  request had merged while never putting the branch's content on the base; making that premise
  faithful is a one-line fixture change, and the assertion it protects — that the *lookup*
  drives the mission grain's verdict — is untouched.
- **Insight**: `${CLAIMS_LIB_DIR}` is one level deeper than `${SCRIPT_DIR}`, and a wrong
  `../..` fails silently.
  **Context**: `claim-mergeability.sh` reaches the ship lib as `${SCRIPT_DIR}/../../ship/...`;
  from `lib/claims.sh` the same file is three levels up. The guarded source made the wrong path
  a no-op rather than an error, so the subtraction simply did not happen and the only symptom
  was a test failing two layers away. The guard is still right — an absent rule over-strands
  rather than over-deletes — which is why the hermetic rows assert the *behaviour* and not that
  the file was found.
